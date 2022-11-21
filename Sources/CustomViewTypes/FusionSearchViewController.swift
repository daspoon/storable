/*

*/

import UIKit
import CoreData


class FusionSearchViewController : UITableViewController, UITextFieldDelegate
  {
    /// Identifiers for table view sections
    enum Section : Int, CaseIterable
      { case level, skills, fusions  }


    /// Provide detail annotation on skill choice cells.
    struct SkillDetail : ChoiceCellOptions
      {
        static func detail(for skill: Skill) -> String?
          { skill.element }
      }


    /// The state of the fusion search process.
    enum State
      {
        /// The search is pending.
        case configuration

        /// The search is in progress,
        case active(FusionSearch, [(recipe: [Fusion], cost: Int)]) // the search is in progress

        /// The search is complete.
        case done([(recipe: [Fusion], cost: Int)]) // the search is complete
      }


    let persona : Persona
    let searchContext : SearchContext<Skill>

    var levelCap : Int? = 6 // TODO: Player level
    var inventorySize : Int = 8
    var inventoryDemons : [Persona] = []
    var skillChoices : [Choice<Skill>] = []
      {
        didSet {
          skillAddButton.isEnabled = skillChoices.count < 8
          fuseButton.isEnabled = skillChoices.allSatisfy {$0.isResolved}
        }
      }

    var resetSearchBarButtonItem : UIBarButtonItem!
    var levelField : UITextField!
    var skillAddButton : UIButton!
    var fuseButton : UIButton!
    var editingTablePath : IndexPath?

    var searchState : State = .configuration
      { didSet { searchStateDidChange() } }


    init(persona p: Persona)
      {
        persona = p
        searchContext = SearchContext<Skill>(DataModel.shared.managedObjectContext, searchKey: "name", additionalPredicates: [
          .init(format: "unique = nil"),
          .init(format: "element != \"trait\""),
          .init(format: "not element in {" + DataModel.shared.configuration.elementsIncompatible(with: p.inherits).map({"'\($0)'"}).joined(separator: ", ") + "}"),
        ])

        super.init(style: .grouped)
      }


    /// Return the list of search results found so far.
    var searchResults : [(recipe: [Fusion], cost: Int)]
      {
        switch searchState {
          case .configuration : return []
          case .active(_, let results), .done(let results) :
            return results
        }
      }


    /// Add a new entry to the skill choices.
    @objc func addSkill(_ sender: UIButton)
      {
        let insertionPath = IndexPath(row: skillChoices.count, section: Section.skills.rawValue)

        skillChoices.append(.unresolved(""))

        tableView.performBatchUpdates {
          self.tableView.insertRows(at: [insertionPath], with: .automatic)
        } completion: { complete in
          guard let cell = self.tableView.cellForRow(at: insertionPath) as? ChoiceCell<Skill, SkillDetail> else { preconditionFailure("TF") }
          cell.nameField.becomeFirstResponder()
        }
      }


    /// Remove an existing from the skill choices.
    @objc func removeSkill(_ sender: UITableViewCell)
      {
        guard let path = tableView.indexPath(for: sender) else { preconditionFailure("invalid argument") }

        skillChoices.remove(at: path.row)

        tableView.performBatchUpdates {
          self.tableView.deleteRows(at: [path], with: .automatic)
        }
      }


    /// Either initiate or advance the search process according to our searchState.
    @objc func performFusionSearch(_ sender: UIButton)
      {
        switch searchState {
          case .configuration :
            searchState = .active(try! FusionSearch(target: persona, inventorySize: inventorySize, inventoryDemons: inventoryDemons, maxLevel: levelCap), [])
            performFusionSearch(sender)
          case .active(var fusionSearch, let results) :
            if let result = try! fusionSearch.nextResult() {
              searchState = .active(fusionSearch, results + [result])
              tableView.performBatchUpdates {
                self.tableView.insertRows(at: [IndexPath(row: results.count, section: Section.fusions.rawValue)], with: .automatic)
              }
            }
            else {
              searchState = .done(results)
            }
          case .done :
            break
        }
      }


    /// Reset the search process, clearing the results.
    @objc func resetFusionSearch(_ sender: UIBarButtonItem)
      {
        searchState = .configuration

        // Reload the fusions section of our table view.
        tableView.reloadSections([Section.fusions.rawValue], with: .automatic)
      }


    /// Update the appearance and enabled state of various UI elements in response to a change in our searchState.
    func searchStateDidChange()
      {
        let searchIsActive = {guard case .configuration = searchState else {return true}; return false}()
        let searchIsComplete = {guard case .done = searchState else {return false}; return true}()

        resetSearchBarButtonItem.isEnabled = searchIsActive

        fuseButton.setImage(UIImage(systemName: searchIsActive ? "forward.frame" : "play")!, for: .normal)
        fuseButton.isEnabled = searchIsComplete == false
      }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: persona.name, subtitle: "Inherits \(persona.inherits)")

        resetSearchBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(resetFusionSearch(_:)))
        navigationItem.rightBarButtonItem = resetSearchBarButtonItem

        levelField = UITextField()
        levelField.text = levelCap.map {"\($0)"}
        levelField.textAlignment = .right
        levelField.placeholder = "<player level>"
        levelField.backgroundColor = .secondarySystemFill
        levelField.borderStyle = .roundedRect
        levelField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        levelField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        levelField.delegate = self
        levelField.addTarget(self, action: #selector(textFieldContentDidChange(_:)), for: .editingChanged)
        levelField.returnKeyType = .done

        skillAddButton = .systemButton(with: UIImage(systemName: "plus")!, target: self, action: #selector(addSkill(_:)))

        fuseButton = .systemButton(with: UIImage(systemName: "hammer")!, target: self, action: #selector(performFusionSearch(_:)))

        tableView.register(ChoiceCell<Skill,SkillDetail>.self, forCellReuseIdentifier: "skillCell")
        tableView.register(KeyValueDisclosureCell.self, forCellReuseIdentifier: "fusionCell")

        searchStateDidChange()
      }


    // UITextFieldDelegate

    func textField(_ sender: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
      {
        // Allow replacement if the resulting text is either empty or represents a positive integer
        let text = (sender.text ?? "").replacingCharactersIn(range, with: string)
        return text == "" || Int(text).map({0 < $0}) == .some(true)
      }

    @objc func textFieldContentDidChange(_ sender: UITextField)
      {
        levelCap = Int(sender.text ?? "")
      }

    func textFieldShouldEndEditing(_ sender: UITextField) -> Bool
      { (sender.text ?? "") != "" }

    func textFieldShouldReturn(_ sender: UITextField) -> Bool
      {
        sender.resignFirstResponder()
        return true
      }

    func textFieldDidEndEditing(_ sender: UITextField)
      {
        if Int(sender.text ?? "") == nil {
          sender.text = levelCap.map {"\($0)"}
        }
      }


    // UITableViewDataSource

    override func numberOfSections(in sender: UITableView) -> Int
      { Section.allCases.count }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        guard let section = Section(rawValue: i) else { fatalError("invalid section index: \(i)") }

        switch section {
          case .level :
            return 0
          case .skills :
            return skillChoices.count
          case .fusions :
            return searchResults.count
        }
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        guard let section = Section(rawValue: path.section) else { fatalError("invalid table path: \(path)") }

        switch section {
          case .skills :
            let cell = sender.dequeueReusableCell(of: ChoiceCell<Skill,SkillDetail>.self, withIdentifier: "skillCell", for: path)
            cell.state = (
              searchContext,
              {self.skillChoices[path.row]},
              {self.skillChoices[path.row] = $0},
              {self.editingTablePath = $0 ? path : nil; sender.performBatchUpdates{}}
            )
            return cell
          case .fusions :
            let cell = sender.dequeueReusableCell(of: KeyValueDisclosureCell.self, withIdentifier: "fusionCell", for: path)
            let result = searchResults[path.row]
            cell.keyAndValue = (key: result.recipe.last!.inputs.map({$0.name}).joined(separator: " + "), value: "\(result.cost)")
            return cell
          default :
            preconditionFailure("unexpected path: \(path)")
        }
      }


    override func tableView(_ sender: UITableView, canEditRowAt path: IndexPath) -> Bool
      { Section(rawValue: path.section) == .skills }


    override func tableView(_ sender: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt path: IndexPath)
      {
        guard case .skills = Section(rawValue: path.section), case .delete = editingStyle else { preconditionFailure("invalid argument") }

        skillChoices.remove(at: path.row)
        sender.deleteRows(at: [path], with: .automatic)
      }


    // UITableViewDelegate

    override func tableView(_ sender: UITableView, viewForHeaderInSection i: Int) -> UIView?
      {
        guard let section = Section(rawValue: i) else { fatalError("invalid section index: \(i)") }

        let contentView : UIView
        switch section {
          case .level :
            contentView = UIStackView(axis: .horizontal, alignment: .center, arrangedSubviews: [
              UILabel { $0.text = "MAX LEVEL"; $0.textColor = .secondaryLabel; },
              levelField,
            ])
          case .skills :
            contentView = UIStackView(axis: .horizontal, alignment: .center, arrangedSubviews: [
              UILabel { $0.text = "SKILLS"; $0.textColor = .secondaryLabel; },
              UIView(),
              skillAddButton,
            ])
          case .fusions :
            contentView = UIStackView(axis: .horizontal, alignment: .center, arrangedSubviews: [
              UILabel { $0.text = "FUSIONS"; $0.textColor = .secondaryLabel; },
              UIView(),
              fuseButton,
            ])
        }
        return UIView(wrapping: contentView, insets: .tableCellInsets)
      }


    override func tableView(_ sender: UITableView, heightForRowAt path: IndexPath) -> CGFloat
      {
        // The currently editing skill cell is given extra height to account for its underlying table view.
        return path == editingTablePath ? 4 * 36 : 36
      }


    override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        guard let section = Section(rawValue: path.section) else { fatalError("invalid index path: \(path)") }

        switch section {
          case .fusions :
            let result = searchResults[path.row]
            navigationController?.pushViewController(RecipeViewController(target: persona, recipe: result.recipe, cost: result.cost), animated: true)
          default :
            break
        }
      }


    override func tableView(_ sender: UITableView, editingStyleForRowAt path: IndexPath) -> UITableViewCell.EditingStyle
      { Section(rawValue: path.section) == .skills ? .delete : .none }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
