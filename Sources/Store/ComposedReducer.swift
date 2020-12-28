//
//  ComposedReducer.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public extension Reducer {
    
    @inlinable
    static func ..<O : Reducer>(lhs: Self, rhs: O) -> LPComposedReducer<Self, O> where SideEffect == Void, Action == O.Action, State == O.State {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    static func ..<O : Reducer>(lhs: Self, rhs: O) -> RPComposedReducer<Self, O> where O.SideEffect == Void, Action == O.Action, State == O.State {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    static func ..<O : Reducer>(lhs: Self, rhs: O) -> CSComposedReducer<Self, O> where SideEffect == O.SideEffect, SideEffect : ExpressibleByArrayLiteral, Action == O.Action, State == O.State {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Reducer>(with other: O) -> LPComposedReducer<Self, O> where SideEffect == Void, Action == O.Action, State == O.State {
        LPComposedReducer(r1: self, r2: other)
    }
    
    @inlinable
    func compose<O : Reducer>(with other: O) -> RPComposedReducer<Self, O> where Action == O.Action, State == O.State, O.SideEffect == Void {
        RPComposedReducer(r1: self, r2: other)
    }
    
    @inlinable
    func compose<O : Reducer>(with other: O) -> CSComposedReducer<Self, O> where State == O.State, Action == O.Action, SideEffect == O.SideEffect, SideEffect : ExpressibleByArrayLiteral {
        CSComposedReducer(r1: self, r2: other)
    }
    
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


public struct LPComposedReducer<R1 : Reducer, R2 : Reducer> : Reducer where R1.SideEffect == Void, R1.Action == R2.Action, R1.State == R2.State {
    
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
    public func apply(to state: inout R1.State, action: R1.Action) -> R2.SideEffect? {
        r1.apply(to: &state, action: action)
        return r2.apply(to: &state, action: action)
    }
    
}


public struct RPComposedReducer<R1 : Reducer, R2 : Reducer> : Reducer where R2.SideEffect == Void, R1.Action == R2.Action, R1.State == R2.State {
    
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
    public func apply(to state: inout R1.State, action: R1.Action) -> R1.SideEffect? {
        let out = r1.apply(to: &state, action: action)
        r2.apply(to: &state, action: action)
        return out
    }
    
}


public struct CSComposedReducer<R1 : Reducer, R2 : Reducer> : Reducer where R1.State == R2.State, R1.Action == R2.Action, R1.SideEffect == R2.SideEffect, R1.SideEffect : ExpressibleByArrayLiteral, R1.SideEffect.ArrayLiteralElement == R1.SideEffect {
    
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
    public func apply(to state: inout R1.State, action: R1.Action) -> R1.SideEffect? {
        let s1 = r1.apply(to: &state, action: action)
        let s2 = r2.apply(to: &state, action: action)
        return s1.flatMap{s1 in s2.map{s2 in [s1, s2]} ?? s2} ?? s1
    }
    
}
