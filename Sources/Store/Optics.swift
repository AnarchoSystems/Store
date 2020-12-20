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
    
}
