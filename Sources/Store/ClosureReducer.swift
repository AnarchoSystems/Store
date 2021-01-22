//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 30.12.20.
//

import Foundation


public struct ClosureReducer<State, Action : DynamicAction> : Reducer {
    
    @usableFromInline
    let _apply: (inout State, Action) -> [DynamicEffect]
    
    @inlinable
    public init(_ apply: @escaping (inout State, Action) -> [DynamicEffect]) {
        self._apply = apply
    }
    
    @inlinable
    public func apply(to state: inout State, action: Action) -> [DynamicEffect] {
        _apply(&state, action)
    }
    
}
