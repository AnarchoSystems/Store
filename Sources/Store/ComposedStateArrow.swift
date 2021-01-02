//
//  ComposedStateArrow.swift
//  
//
//  Created by Markus Pfeifer on 21.12.20.
//

import Foundation


public extension StateArrow {
    
    static func ..<O : StateArrow>(lhs: Self, rhs: O) -> ComposedStateArrow<Self, O> where NewEffect == O.Effect, NewState == O.State {
        lhs.compose(with: rhs)
    }
    
    func compose<O : StateArrow>(with other: O) -> ComposedStateArrow<Self, O> where NewEffect == O.Effect, NewState == O.State {
        ComposedStateArrow(a1: self, a2: other)
    }
    
}


public struct ComposedStateArrow<A1 : StateArrow, A2 : StateArrow> : StateArrow where A1.NewEffect == A2.Effect, A1.NewState == A2.State {
    
    @usableFromInline
    let a1 : A1
    @usableFromInline
    let a2 : A2
    
    @usableFromInline
    init(a1: A1, a2: A2){(self.a1, self.a2) = (a1, a2)}
    
    @inlinable
    public func apply(to state: inout A2.NewState,
                      change: (inout A1.State) -> [A1.Effect]) -> [A2.NewEffect] {
        a2.apply(to: &state) {partial in
            a1.apply(to: &partial, change: change)
        }
    }
    
}
