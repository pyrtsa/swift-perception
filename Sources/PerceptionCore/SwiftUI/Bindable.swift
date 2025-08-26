#if canImport(SwiftUI)
  import SwiftUI

  /// A property wrapper type that supports creating bindings to the mutable properties of
  /// perceptible objects.
  ///
  /// > Important: This is a back-port of SwiftUI's `Bindable` property wrapper.
  @available(
    iOS,
    introduced: 13,
    obsoleted: 17,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(
    macOS,
    introduced: 10.15,
    obsoleted: 14,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(
    tvOS,
    introduced: 13,
    obsoleted: 17,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(
    watchOS,
    introduced: 6,
    obsoleted: 10,
    message: "Use @Bindable without the 'Perception.' prefix."
  )
  @available(visionOS, unavailable)
  @dynamicMemberLookup
  @propertyWrapper
  public struct Bindable<Value> {
    /// The wrapped object.
    public var wrappedValue: Value

    /// The bindable wrapper for the object that creates bindings to its properties using dynamic
    /// member lookup.
    public var projectedValue: Bindable<Value> {
      self
    }

    /// Returns a binding to the value of a given key path.
    public subscript<T>(
      dynamicMember keyPath: ReferenceWritableKeyPath<Value, T>
    ) -> Binding<T> where Value: AnyObject & Perceptible {
      #if DEBUG && canImport(SwiftUI)
        let isInPerceptionTracking = _PerceptionLocals.isInPerceptionTracking
      #endif
      if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *),
         !isObservationBeta,
         let subject = wrappedValue as? any (AnyObject & Observable)
      {
        func open<S: AnyObject & Observable>(_ subject: S) -> Binding<T> {
          @SwiftUI.Bindable var subject = subject
          let keyPath = unsafeDowncast(keyPath, to: ReferenceWritableKeyPath<S, T>.self)
          #if DEBUG && canImport(SwiftUI)
            return $subject[dynamicMember: \.[isPerceptionTracking: isInPerceptionTracking, keyPath: keyPath]]
          #else
            return $subject[dynamicMember: keyPath]
          #endif
        }
        return open(subject)
      } else {
        return Binding {
          #if DEBUG && canImport(SwiftUI)
            wrappedValue[isPerceptionTracking: isInPerceptionTracking, keyPath: keyPath]
          #else
            wrappedValue[keyPath: keyPath]
          #endif
        } set: { newValue, transaction in
          withTransaction(transaction) {
            wrappedValue[keyPath: keyPath] = newValue
          }
        }
      }
    }

    @available(*, unavailable, message: "The wrapped value must be an object that conforms to Perceptible")
    public init(wrappedValue: Value) {
      fatalError()
    }

    @available(*, unavailable, message: "The wrapped value must be an object that conforms to Perceptible")
    public init(projectedValue: Bindable<Value>) {
      fatalError()
    }
  }

  extension Bindable where Value: ObservableObject {
    @available(*, unavailable, message: "@Bindable only works with Perceptible types. For ObservableObject types, use @ObservedObject instead.")
    public init(wrappedValue: Value) {
      fatalError()
    }
  }

  extension Bindable where Value: AnyObject, Value: Perceptible {
    public init(wrappedValue: Value) {
      self.wrappedValue = wrappedValue
    }
    public init(_ wrappedValue: Value) {
      self.wrappedValue = wrappedValue
    }
    public init(projectedValue: Bindable<Value>) {
      self = projectedValue
    }
  }

  @available(visionOS, unavailable)
  extension Bindable: Identifiable where Value: Identifiable {
    public var id: Value.ID {
      wrappedValue.id
    }
  }

  @available(visionOS, unavailable)
  extension Bindable: Sendable where Value: Sendable {}

  private final class Observer<Object>: ObservableObject {
    var object: Object
    init(_ object: Object) {
      self.object = object
    }
  }

  extension Observer: Equatable where Object: AnyObject {
    static func == (lhs: Observer, rhs: Observer) -> Bool {
      lhs.object === rhs.object
    }
  }

  #if DEBUG
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
    extension Observable where Self: AnyObject {
      fileprivate subscript<Member>(
        isPerceptionTracking isPerceptionTracking: Bool,
        keyPath keyPath: ReferenceWritableKeyPath<Self, Member>
      ) -> Member {
        get {
          _PerceptionLocals.$isInPerceptionTracking.withValue(isPerceptionTracking) {
            self[keyPath: keyPath]
          }
        }
        set {
          self[keyPath: keyPath] = newValue
        }
      }
    }

    extension Perceptible {
      fileprivate subscript<Member>(
        isPerceptionTracking isPerceptionTracking: Bool,
        keyPath keyPath: ReferenceWritableKeyPath<Self, Member>
      ) -> Member {
        get {
          _PerceptionLocals.$isInPerceptionTracking.withValue(isPerceptionTracking) {
            self[keyPath: keyPath]
          }
        }
        set {
          _PerceptionLocals.$isInPerceptionTracking.withValue(isPerceptionTracking) {
            self[keyPath: keyPath] = newValue
          }
        }
      }
    }
  #endif
#endif
