//
//  DiscriminatedComposition.swift
//  
//
//  Created by Markus Pfeifer on 30.12.20.
//

import Foundation



public extension Reducer {

    @inlinable
    func compose<D : Discriminator, O : Reducer>(with other: O, using discriminator: D) -> ADComposedReducer<D, Self, O> where O.State == State, O.SideEffect == SideEffect, D.A == Action, D.B == O.Action {
        ADComposedReducer(d: discriminator, r1: self, r2: other)
    }
    
    @inlinable
    func compose<A, O : Reducer>(with other: O, using cata: @escaping (A, (Action) -> SideEffect?, (O.Action) -> SideEffect?) -> SideEffect?) -> CADComposedReducer<A, Self, O> where O.State == State, O.SideEffect == SideEffect {
        CADComposedReducer(closure: cata, r1: self, r2: other)
    }
    
}


public struct CADComposedReducer<Action, R1 : Reducer, R2 : Reducer> : Reducer where R1.State == R2.State, R1.SideEffect == R2.SideEffect {
    
    @usableFromInline
    typealias Cata = (Action, (R1.Action) -> R1.SideEffect?, (R2.Action) -> R2.SideEffect?) -> R1.SideEffect?
    
    @usableFromInline
    let closure : Cata
    @usableFromInline
    let r1 : R1
    @usableFromInline
    let r2 : R2
    
    @usableFromInline
    init(closure: @escaping Cata, r1: R1, r2: R2){
        self.closure = closure
        self.r1 = r1
        self.r2 = r2
    }
    
    @inlinable
    public func apply(to state: inout R1.State, action: Action) -> R1.SideEffect? {
        closure(action, {r1.apply(to: &state, action: $0)}, {r2.apply(to: &state, action: $0)})
    }
    
}


public struct ADComposedReducer<D : Discriminator, R1 : Reducer, R2 : Reducer> : Reducer where D.A == R1.Action, D.B == R2.Action, R1.SideEffect == R2.SideEffect, R1.State == R2.State {
    
    @usableFromInline
    let discriminator : D
    @usableFromInline
    let r1 : R1
    @usableFromInline
    let r2 : R2
    
    @usableFromInline
    init(d: D, r1: R1, r2: R2){
        self.discriminator = d
        self.r1 = r1
        self.r2 = r2
    }
    
    @inlinable
    public func apply(to state: inout R1.State, action: D.Sum) -> R1.SideEffect? {
        discriminator.cata(action, onA: {r1.apply(to: &state, action: $0)}, onB: {r2.apply(to: &state, action: $0)}).flatMap{$0}
    }
    
}
