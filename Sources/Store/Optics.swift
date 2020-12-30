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
    
    func get(from whole: WholeState) -> PartialState
    
    func set(in whole: inout WholeState, newValue: PartialState)
    
}


public extension Lens {
    
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


extension WritableKeyPath : Lens {
    
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
    
    associatedtype PartialState
    associatedtype WholeState
    
    func apply<T>(to whole: inout WholeState, change: (inout PartialState) -> T) -> T?
    
    func tryGet(from whole: WholeState) -> PartialState?
    
    func put(in whole: inout WholeState, newValue: PartialState)
    
}


public extension Prism {
    
    @inlinable
    func tryGet(from whole: WholeState) -> PartialState? {
        var copy = whole
        return apply(to: &copy){part in part}
    }
    
    @inlinable
    func put(in whole: inout WholeState,
             newValue: PartialState) {
        apply(to: &whole){$0 = newValue}
    }
    
}

public protocol Extractor {
    
    associatedtype SuperType
    associatedtype SubType
    
    func downCast(_ object: SuperType) -> SubType?

}

public protocol Embedding : Extractor {
    
    associatedtype SuperType
    associatedtype SubType
    
    func cast(_ object: SubType) -> SuperType
    
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
