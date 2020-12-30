//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 30.12.20.
//

import Foundation


public struct ClosureReducer<State, Action, Effect> : Reducer {
    
    @usableFromInline
    let _apply: (inout State, Action) -> Effect
    
    @inlinable
    public init(_ apply: @escaping (inout State, Action) -> Effect) {
        self._apply = apply
    }
    
    @inlinable
    public func apply(to state: inout State, action: Action) -> Effect? {
        _apply(&state, action)
    }
    
}


public protocol ReducerWrapper : Reducer {
    
    associatedtype Wrapped : Reducer
    var wrapped : Wrapped{get}
    
}


public extension ReducerWrapper {
    
    func apply(to state: inout Wrapped.State, action: Wrapped.Action) -> Wrapped.SideEffect? {
        wrapped.apply(to: &state, action: action)
    }
    
}
