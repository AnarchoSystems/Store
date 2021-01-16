//
//  ReducerWrapper.swift
//  
//
//  Created by Markus Pfeifer on 30.12.20.
//

import Foundation


public struct ClosureReducer<State> : Reducer {
    
    @usableFromInline
    let _apply: (inout State, DynamicAction) -> [DynamicEffect]
    
    @inlinable
    public init(_ apply: @escaping (inout State, DynamicAction) -> [DynamicEffect]) {
        self._apply = apply
    }
    
    @inlinable
    public func apply(to state: inout State, action: DynamicAction) -> [DynamicEffect] {
        _apply(&state, action)
    }
    
}
