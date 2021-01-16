//
//  ComposedReducer.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation

infix operator <> : AdditionPrecedence

public extension Reducer {
    
    @inlinable
    static func <><O : Reducer>(lhs: Self, rhs: O) -> ComposedReducer<Self, O> where O.State == State {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Reducer>(with other: O) -> ComposedReducer<Self, O> where O.State == State {
        ComposedReducer(r1: self, r2: other)
    }
    
}


public struct ComposedReducer<R1 : Reducer, R2 : Reducer> : Reducer where R1.State == R2.State {
    
    @usableFromInline
    let r1 : R1
    @usableFromInline
    let r2 : R2
    
    @usableFromInline
    init(r1: R1, r2: R2){
        self.r1 = r1
        self.r2 = r2
    }
    
    @inlinable
    public func apply(to state: inout R1.State,
                      action: DynamicAction) -> [DynamicEffect] {
        var result = r1.apply(to: &state, action: action)
        result.append(contentsOf: r2.apply(to: &state, action: action))
        return result
    }
    
}
