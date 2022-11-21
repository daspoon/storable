/*

  An implementation of fusion search -- i.e. find the least cost fusion for a given demon using knowledge of the player's level and inventory/compendium contents.

  The basic idea is:
    - start with a table mapping demons to 1-step fusion recipes
    - each such recipe corresponds to a two-level tree, with the target demon as root and the ingredient demons as leaves
    - classify leaf nodes as either 'have' or 'need', depending on whether or not they exist in the compendium; classify the root node as 'fuse'
    - 'need' nodes are expanded by replacement with a 1-step fusion subtree for the associated demon
    - a fusion tree has a cost which we want to minimize...
        - the cost of a leaf node is the compendium extraction cost of the associated demon
        - the cost of a fuse node is the sum of the costs of its subtrees
        * we might consider inventory demons to have zero extraction cost, but that can apply only to the first usage
    - the search state is a list of fusion trees, sorted by increasing cost; initially it contains the 1-step fusion trees for the target demon
    - a search step involves removing the first tree and...
        - returning that tree if it has no 'need' nodes
        - otherwise, inserting all expansions of the removed tree
    - note that a demon may appear repeatedly as an ingredient in a fusion tree, but it must have at most one associated fuse node...
        - each state must maintain knowledge of fused nodes and treat them as existing in the compendium and/or inventory
    - it would be best to avoid repeated calculation of the best fusion of any particular 'intermediate' ingredient...

*/

import CoreData


struct FusionSearch
  {
    /// A multi-step recipe for creating the target persona.
    indirect enum Tree
      {
        case leaf(Persona)
        case node(Fusion, [Tree])
      }


    /// A state of the search process
    struct State
      {
        enum Progress { case initial, active, done }

        /// The tree of fusions proposed to create the target demon.
        var tree : Tree
        /// The progress of the fusion tree traversal...
        var progress : Progress
        /// The stack which identifies the current node in the traversal.
        var stack : [(index: Int, count: Int)]
        /// The accumulated cost to reach the state.
        let cost : Int
        /// Represents the set of set of demons which are being created (to avoid cycles).
        var pending : IndexSet
        /// The compendium contents as a collection of demon indices.
        var compendium : IndexSet
        /// The inventory contents as a collection of demon indices.
        var inventory : IndexSet


        /// Create an initial state for the given target demon and compendium/inventory contents.
        init(target: Persona, compendium: IndexSet, inventory: IndexSet)
          {
            self.tree = .leaf(target)
            self.progress = .initial
            self.stack = []
            self.cost = target.estimatedFusionCost
            self.pending = []
            self.compendium = compendium
            self.inventory = inventory
          }


        /// Create a derived state by expanding the current leaf node according to the given fusion.
        init(expanding parent: Self, with fusion: Fusion)
          {
            // The current node of the parent's traversal must be a leaf whose demon matches the given fusion and is not in the compendium.
            guard case .active = parent.progress else { preconditionFailure("invalid state") }
            let path = IndexPath(indexes: parent.stack.map {$0.0})
            guard case .leaf(fusion.output) = parent.tree[path], !parent.compendium.contains(fusion.output.index) else { preconditionFailure("invalid argument") }

            tree = {var t = parent.tree; t[path] = .node(fusion, fusion.inputs.map {.leaf($0)}); return t}()
            progress = .active
            stack = parent.stack// + [(0, fusion.inputs.count)]
            pending = parent.pending.union([fusion.output.index])
            compendium = parent.compendium
            inventory = parent.inventory

            // The parent cost is refined by replacing the estimated cost of the fusion output with the sum of the estimated costs of the fusion inputs.
            cost = fusion.inputs.reduce(parent.cost - fusion.output.estimatedFusionCost) { (total, input) in
              switch (parent.compendium.contains(input.index), parent.inventory.contains(input.index)) {
                case (_,  true) : return total
                case (true,  _) : return total + input.summonCost
                case (false, _) : return total + input.estimatedFusionCost
              }
            }
          }


        /// Advance the post-order traversal to the next leaf which requires fusion, returning the associated demon (or nil if no such leaf exists)..
        mutating func advance() -> Persona?
          {
            switch progress {
              case .initial :
                // Initiate the traversal, returning the root/target demon.
                progress = .active
                return tree.demon

              case .active :
                // The current node corresponds to the previously introduced fusion; extend the traversal context to indicate its first child
                // and continue the traversal (to locate the next leaf requiring fusion).
                guard case .node(_, let subtrees) = tree[IndexPath(indexes: stack.map {$0.0})] else { preconditionFailure("TF") }
                stack += [(0, subtrees.count)]
                while let (i, n) = stack.last {
                  if i < n {
                    guard case .leaf(let demon) = tree[IndexPath(indexes: stack.map {$0.0})] else { preconditionFailure("TF") }
                    if compendium.contains(demon.index) {
                      log("skipping captured demon \(demon.name) of state \(tree)")
                      stack[stack.count-1].index += 1
                      continue
                    }
                    log("returning required demon \(demon.name) of state \(tree)")
                    return demon
                  }
                  else {
                    // Pop the stack to remove completed fusion nodes, adding each output demon to both compendium and inventory.
                    repeat {
                      stack.removeLast(1)
                      let output = tree[IndexPath(indexes: stack.map {$0.0})].demon
                      compendium.insert(output.index)
                      inventory.insert(output.index)
                      if stack.count > 0 {
                        stack[stack.count-1].index += 1
                      }
                    }
                    while stack.count > 0 && stack[stack.count-1].index == stack[stack.count-1].count
                  }
                }
                progress = .done
                log("exhausted state \(tree)")
                return nil

              case .done :
                return nil
            }
          }

        /// Indicates whether or not the associated fusion tree is complete (i.e. all leaf demons exist in the compendium).
        var goal : Bool
          { tree.leaves.allSatisfy { self.compendium.contains($0.index) } }
      }


    /// The cost of a state is
    typealias Cost = Int


    /// The maximum level for fusion output.
    let maxLevel : Int?

    /// The materialized states of the search space ordered by increasing cost.
    var states : [State]


    /// Initialize a search process to create the given demon.
    init(target: Persona, inventorySize: Int, inventoryDemons: [Persona], maxLevel k: Int?) throws
      {
        precondition(k.map {Int(target.level) <= $0} ?? true)

        /// Form the initial state from the target demon together with the compendium and inventory content.
        let compendiumDemons = try DataModel.shared.fetchObjects(of: Persona.self, satisfying: .init(format: "captured = TRUE"))
        let initialState = State(target: target, compendium: IndexSet(compendiumDemons.map {$0.index}), inventory: IndexSet(inventoryDemons.map {$0.index}))

        states = [initialState]
        maxLevel = k

        log("\(initialState.tree)")
      }


    /// Return the next least cost recipe, or nil if there are none.
    mutating func nextResult() throws -> (recipe: [Fusion], cost: Int)?
      {
        while var state = states.first {
          log("expanding \(state)...")
          // Dequeue the least-cost state.
          states.removeFirst()

          // Advance the state's traversal to the next demon requiring fusion; if none exists then the fusion tree is complete, so return it...
          guard let demon = state.advance() else { precondition(state.goal); return (state.tree.fusions, state.cost) }

          // Insert a new state for each possible fusion of the required demon, ignoring those which exceed the level cap or lead to a cycle...
          for fusion in demon.fusionsToProduce {
            guard fusion.inputs.allSatisfy({$0.level < (maxLevel ?? .max) && state.pending.contains($0.index) == false}) else { continue }
            states.sortedInsert({let s=State(expanding: state, with: fusion); log("inserted \(state)..."); return s}(), usingComparator: compareStates)
          }
        }

        return nil
      }


    func compareStates(_ lhs: State, _ rhs: State) -> ComparisonResult
      { lhs.cost.compare(rhs.cost) }
  }


extension FusionSearch.Tree : CustomStringConvertible
  {
    var description : String
      {
        switch self {
          case .leaf(let persona) :
            return persona.name
          case .node(let fusion, let subtrees) :
            return "(" + fusion.output.name + " = " + subtrees.map({$0.description}).joined(separator: " + ") + ")"
        }
      }
  }


extension FusionSearch.Tree
  {
    /// Retrieve or replace the node at a given index path.
    subscript (_ path: IndexPath) -> Self
      {
        get {
          guard case .some(let i) = path.first else { return self }
          guard case .node(_, let subtrees) = self else { preconditionFailure("invalid argument") }
          return subtrees[i][path.dropFirst()]
        }
        set {
          guard case .some(let i) = path.first else { self = newValue; return }
          guard case .node(let fusion, var subtrees) = self else { preconditionFailure("invalid argument") }
          subtrees[i][path.dropFirst()] = newValue
          self = .node(fusion, subtrees)
        }
      }

    /// Return the demon at the root of the tree.
    var demon : Persona
      {
        switch self {
          case .leaf(let demon) :
            return demon
          case .node(let fusion, _) :
            return fusion.output
        }
      }

    /// Return the sequence of fusions (obtained via post-order traversal) required to product the root demon.
    var fusions : [Fusion]
      {
        switch self {
          case .leaf :
            return []
          case .node(let fusion, let subtrees) :
            return subtrees.flatMap({$0.fusions}) + [fusion]
        }
      }

    /// Return the list of demons represented by the leaves of the tree.
    var leaves : [Persona]
      {
        switch self {
          case .leaf(let demon) :
            return [demon]
          case .node(_, let subtrees) :
            return subtrees.flatMap {$0.leaves}
        }
      }
  }
