//
//  Optics.swift
//  
//
//  Created by Markus Pfeifer on 09.12.20.
//

import Foundation


public protocol Lens {
    
    associatedtype PartialState
    associatedtype WholeState
    
    func apply<T>(to whole: inout WholeState, change: (inout PartialState) -> T) -> T
    
}


public protocol GetSetLens : Lens {
    
    func get(from whole: WholeState) -> PartialState
    
    func set(in whole: inout WholeState, newValue: PartialState)
    
}


public extension GetSetLens {
    
    @inlinable
    func get(from whole: WholeState) -> PartialState {
        var copy = whole
        return apply(to: &copy) {part in part}
    }
    
    @inlinable
    func set(in whole: inout WholeState, newValue: PartialState) {
        apply(to: &whole, change: {$0 = newValue})
    }
    
}


extension WritableKeyPath : GetSetLens {
    
    @inlinable
    public func apply<T>(to whole: inout Root,
                         change: (inout Value) -> T) -> T {
        change(&whole[keyPath: self])
    }
    
    @inlinable
    public func get(from whole: Root) -> Value {
        whole[keyPath: self]
    }
    
    @inlinable
    public func set(in whole: inout Root, newValue: Value) {
        whole[keyPath: self] = newValue
    }
    
}


public protocol Prism {
    
    associatedtype MaybePartialState
    associatedtype WholeState
    
    func apply<T>(to whole: inout WholeState, change: (inout MaybePartialState) -> T) -> T?
    
}

public protocol TryGetPutPrism : Prism {
    
    func tryGet(from whole: WholeState) -> MaybePartialState?
    
    func put(in whole: inout WholeState, newValue: MaybePartialState)
    
}


public extension TryGetPutPrism {
    
    @inlinable
    func tryGet(from whole: WholeState) -> MaybePartialState? {
        var copy = whole
        return apply(to: &copy){part in part}
    }
    
    @inlinable
    func put(in whole: inout WholeState,
             newValue: MaybePartialState) {
        apply(to: &whole){$0 = newValue}
    }
    
}


public protocol OptionalProtocol : ExpressibleByNilLiteral {
    associatedtype Wrapped
    func asOptional() -> Wrapped?
    mutating func mutate<T>(_ closure: (inout Wrapped) -> T) -> T?
    mutating func set(to newValue: Wrapped)
}


extension Optional : OptionalProtocol {
    @inlinable
    public func asOptional() -> Wrapped? {
        self
    }
    @inlinable
    public mutating func mutate<T>(_ closure: (inout Wrapped) -> T) -> T? {
        guard var value = self else {
            return nil
        }
        self = nil
        defer {self = value}
        return closure(&value)
    }
    public mutating func set(to newValue: Wrapped) {
        self = newValue
    }
}


extension WritableKeyPath : Prism, TryGetPutPrism where Value : OptionalProtocol {
    
    @inlinable
    public func apply<T>(to whole: inout Root, change: (inout Value.Wrapped) -> T) -> T? {
        whole[keyPath: self].mutate(change)
    }
    
    @inlinable
    public func tryGet(from whole: Root) -> Value.Wrapped? {
        whole[keyPath: self].asOptional()
    }
    
    @inlinable
    public func put(in whole: inout Root, newValue: Value.Wrapped) {
        whole[keyPath: self].set(to: newValue)
    }
    
}


public protocol Downcast {
    
    associatedtype SuperType
    associatedtype SubType
    
    func downCast(_ object: SuperType) -> SubType?

}

public protocol Embedding : Downcast {
    
    associatedtype SuperType
    associatedtype SubType
    
    func cast(_ object: SubType) -> SuperType
    
}


public struct TopEmbedding<T> : Embedding {
    
    @inlinable
    public init(){}
    
    @inlinable
    public func cast(_ object: T) -> Any {
        object
    }
    
    @inlinable
    public func downCast(_ object: Any) -> T? {
        object as? T
    }
    
}


public struct ClassEmbedding<S,T : AnyObject> : Embedding {
    
    @inlinable
    public init?() {
        guard S.self is T.Type else {
            return nil
        }
    }
    
    @inlinable
    public func cast(_ object: S) -> T {
        object as! T
    }
    
    @inlinable
    public func downCast(_ object: T) -> S? {
        object as? S 
    }
    
}


public struct OptionalEmbedding<T> : Embedding {
    
    @inlinable
    public init(){}
    
    @inlinable
    public func cast(_ object: T) -> T? {
        object
    }
    
    @inlinable
    public func downCast(_ object: T?) -> T? {
        object
    }
    
}


public struct ResultEmbedding<Success, Failure : Error> : Embedding {
    
    @inlinable
    public init(){}
    
    @inlinable
    public func cast(_ object: Success) -> Result<Success, Failure> {
        .success(object)
    }
    
    @inlinable
    public func downCast(_ object: Result<Success, Failure>) -> Success? {
        try? object.get()
    }
    
}


public struct RawEmbedding<R : RawRepresentable> : Embedding {
    
    @inlinable
    public init() {}
    
    @inlinable
    public func cast(_ object: R) -> R.RawValue {
        object.rawValue
    }
    
    @inlinable
    public func downCast(_ object: R.RawValue) -> R? {
        R(rawValue: object)
    }
    
}
