/*

  Created by David Spooner

*/

import CoreData


/// *EditingContext* is a convenience class intended to simplify editing of a managed object graph, providing a child context to maintain editing changes along with a list of actions to be perform on either save or rollback.
/// The created child context is associated with the main queue in order to serve UI elements.

public class EditingContext
  {
    public struct CallbackTrigger : OptionSet
      {
        public let rawValue : Int
        public init(rawValue v: Int) { rawValue = v }
        public static let save = CallbackTrigger(rawValue: 1)
        public static let cancel = CallbackTrigger(rawValue: 2)
        public static let completion = CallbackTrigger(rawValue: 3)
      }

    /// The parent context provided on initialization.
    public let parentContext : NSManagedObjectContext

    /// The child context created on initialization.
    public let childContext : NSManagedObjectContext

    /// The actions to be performed on either save or cancel.
    private var actions : [(message: String, trigger: CallbackTrigger, effect: () throws -> Void)] = []


    /// Create a new editing context on the given parent context.
    public init(name: String = "edit", parent: NSManagedObjectContext)
      {
        parentContext = parent
        childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.name = name
        childContext.parent = parent
        childContext.automaticallyMergesChangesFromParent = true
        childContext.editingContext = self
      }


    deinit
      {
        childContext.editingContext = nil
      }


    /// Enqueue an action to be performed on save, cancel or both.
    public func addAction(_ message: String, on trigger: CallbackTrigger, effect: @escaping () throws -> Void)
      {
        actions.append((message: message, trigger: trigger, effect: effect))
      }


    /// Return a closure to perform the editing actions for a given trigger, enabling execution in a context independent of this object.
    private func actionExecutionClosure(for trigger: CallbackTrigger) -> (() -> Void)
      {
        let actions = self.actions
        return {
          for action in actions {
            guard action.trigger.contains(trigger) else { continue }
            do {
              try action.effect()
              log(action.message)
            }
            catch {
              log("failed to perform '\(action.message)': \(error)")
            }
          }
        }
      }


    /// Return the error which would occur on saving the associated child context. A return or *nil* indicates the child context is free of validation errors and can safely be saved.
    public var validationError : NSError?
      { childContext.validationError }


    /// Save the changes in the local context to the persistent store, invoking the given block on either completion or failure. It is expected that *validationError* on calling this method.
    public func save(onCompletion completion: ((Error?) -> Void)? = nil)
      {
        if let validationError {
          preconditionFailure("validation failed: \(validationError)")
        }

        let performActions = actionExecutionClosure(for: .save)
        childContext.performSave { error in
          if error == nil {
            performActions()
          }
          completion?(error)
        }

        actions = []
      }


    /// Discard the changes to the local context.
    public func cancel()
      {
        let performActions = actionExecutionClosure(for: .cancel)
        performActions()

        childContext.rollback()

        actions = []
      }
  }
