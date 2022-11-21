/*

*/

import UIKit
import CoreData


fileprivate let resolvedImage = UIImage(systemName: "checkmark.seal")!
fileprivate let resolvedColor = UIColor.green
fileprivate let unresolvedImage = UIImage(systemName: "exclamationmark.triangle")!
fileprivate let unresolvedColor = UIColor.red


protocol ChoiceCellOptions
  {
    associatedtype Object
    static func detail(for object: Object) -> String?
  }


class ChoiceCell<Object: NSManagedObject & Named, Options: ChoiceCellOptions> : UITableViewCell, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate where Options.Object == Object
  {
    enum Change
      { case programmatic, viaSelection, viaKeyboardEntry }


    let nameField = {let f = UITextField(); f.placeholder = "\(Object.self) name ..."; f.spellCheckingType = .no; f.autocorrectionType = .no; f.autocapitalizationType = .words; return f}()
    let statusIcon = UIImageView()
    let matchesView = {let t = UITableView(frame: .zero, style: .grouped); t.backgroundColor = .secondarySystemGroupedBackground; return t}()


    var state : (searchContext: SearchContext<Object>, get: () -> Choice<Object>, set: (Choice<Object>) -> Void, onEditingChange: (Bool) -> Void)?
      {
        didSet {
          guard let state else { return }
          selectedValueDidChange(.programmatic, to: state.get())
        }
      }


    func selectedValueDidChange(_ change: Change, to value: Choice<Object>)
      {
        guard let state else { preconditionFailure("invalid state") }

        // If the change was made through user interaction, then propagate the change upward...
        if change != .programmatic {
          state.set(value)
        }

        // If the change was not made through keyboard input, then update the nameField
        if change != .viaKeyboardEntry {
          nameField.text = value.name
        }

        // Update the icon indicating validity
        statusIcon.image = value.isResolved ? resolvedImage : unresolvedImage
        statusIcon.tintColor = value.isResolved ? resolvedColor : unresolvedColor

        // Update the enabled state of the keyboard's return key
        nameField.returnKeyEnabled = value.isResolved
      }


    @objc func textFieldDidChange(_ sender: UITextField)
      {
        guard let state, let name = sender.text else { preconditionFailure("unexpected") }

        // Update the search context with the text field's content.
        state.searchContext.search(for: name)

        // Update the associated value
        let value : Choice<Object>
        switch state.searchContext.matchesByName[name] {
          case .some(let element) :
            value = .resolved(element)
          case .none :
            value = .unresolved(name)
        }

        // Update the status icon
        selectedValueDidChange(.viaKeyboardEntry, to: value)

        // Reload the matches table view.
        matchesView.reloadData()
      }


    // UITableViewCell

    override init(style s: UITableViewCell.CellStyle, reuseIdentifier id: String?)
      {
        super.init(style: s, reuseIdentifier: id)

        contentView.setContentView(UIStackView(axis: .vertical, arrangedSubviews: [
          UIStackView(axis: .horizontal, alignment: .firstBaseline, arrangedSubviews: [nameField, UIView(), statusIcon]),
          matchesView,
        ]), insets: .tableCellInsets)

        nameField.delegate = self
        nameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        nameField.returnKeyType = .done

        matchesView.dataSource = self
        matchesView.delegate = self
        matchesView.register(KeyValueCell.self, forCellReuseIdentifier: "elementCell")
        matchesView.isHidden = true
        // Add thin header and footer views to eliminate blank space above/below first/last cell
        matchesView.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        matchesView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))

        selectionStyle = .none
      }


    override func prepareForReuse()
      {
        state = nil

        super.prepareForReuse()
      }


    // UITextFieldDelegate

    func textFieldDidBeginEditing(_ sender: UITextField)
      {
        guard let state else { preconditionFailure("unexpected") }

        textFieldDidChange(sender)

        // Show the matches table view
        matchesView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: false)
        matchesView.isHidden = false

        // Notify change of state
        state.onEditingChange(true)
      }


    func textFieldDidEndEditing(_ sender: UITextField)
      {
        guard let state else { preconditionFailure("unexpected") }

        // Hide the matches table view
        matchesView.isHidden = true

        // Notify change of state
        state.onEditingChange(false)
      }


    func textFieldShouldReturn(_ sender: UITextField) -> Bool
      {
        assert(state?.get().isResolved == .some(true))

        sender.resignFirstResponder()
        return true
      }


    // UITableViewDataSource

    func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        guard let state else { return 0 }

        return state.searchContext.matches.count
      }


    func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        guard let state else { preconditionFailure("invalid state") }

        let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "elementCell")
        let object = state.searchContext.matches[path.row]
        cell.keyAndValue = (key: object.name, value: Options.detail(for: object))
        return cell
      }


    // UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
      { .leastNormalMagnitude }


    func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        guard let state else { preconditionFailure("invalid state") }

        selectedValueDidChange(.viaSelection, to: .resolved(state.searchContext.matches[path.row]))
      }


    // NSCoder

    required init?(coder: NSCoder)
      { nil }
  }
