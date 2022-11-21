/*

*/

import UIKit


class RecipeViewController : UITableViewController
  {
    struct RecipeCellConfiguration : GenericTableCellConfiguration
      {
        let multiLineLabel = createLabel()

        var contentSubview : UIView
          { multiLineLabel }

        func update(_ cell: GenericTableCell<Self>, for fusion: Fusion)
          {
            multiLineLabel.text = "Fuse " + fusion.output.name + " from :\n"
              + fusion.inputs.map({"  \u{2022} " + $0.name + " (\($0.arcana.name)/\($0.level))"}).joined(separator: "\n")
            multiLineLabel.numberOfLines = 1 + fusion.inputs.count
          }
      }

    typealias RecipeCell = GenericTableCell<RecipeCellConfiguration>


    let target : Persona
    let cost : Int
    let recipe : [Fusion]


    init(target t: Persona, recipe r: [Fusion], cost k: Int)
      {
        target = t
        recipe = r
        cost = k

        super.init(style: .insetGrouped)
      }


    // UIViewController

    override func viewDidLoad()
      {
        navigationItem.titleView = UILabel(title: target.name, subtitle: "\(cost)")

        tableView.register(RecipeCell.self, forCellReuseIdentifier: "recipeCell")
      }


    // UITableViewDataSource

    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { recipe.count }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: RecipeCell.self, withIdentifier: "recipeCell")
        cell.content = recipe[path.row]
        return cell
      }


    override func tableView(_ sender: UITableView, titleForHeaderInSection _: Int) -> String?
      { "FUSION STEPS" }


    override func tableView(_ sender: UITableView, heightForRowAt path: IndexPath) -> CGFloat
      {
        let fusion = recipe[path.row]
        return CGFloat(44 + fusion.inputs.count * 24)
      }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
