//
//  MapAction.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public extension Reducer {
    
    func contraMapAction<F : Function>(_ transform: F) -> ActionMappingReducer<Self, F> where F.Output == Action {
        ActionMappingReducer(r: self, f: transform)
    }
    
    func contraMapAction<NewAction>(_ transform: @escaping (NewAction) -> Action) -> ActionMappingReducer<Self, Closure<NewAction, Action>> {
        ActionMappingReducer(r: self, f: Closure(transform))
    }
    
    func lensAction<L : Lens>(_ lens: L) -> ActionLensingReducer<Self, L> where L.PartialState == Action {
        ActionLensingReducer(r: self, l: lens)
    }
    
    func flatMapAction<F : Function>(_ transform: F) -> ActionFlatMappingReducer<Self, F> where F.Output == Action? {
        ActionFlatMappingReducer(r: self, f: transform)
    }
    
    func flatMapAction<NewAction>(_ transform: @escaping (NewAction) -> Action?) -> ActionFlatMappingReducer<Self, Closure<NewAction, Action?>> {
        ActionFlatMappingReducer(r: self, f: Closure(transform))
    }
    
    func prismAction<P : Prism>(_ prism: P) -> ActionPrismingReducer<Self, P> where P.PartialState == Action {
        ActionPrismingReducer(r: self, p: prism)
    }
    
}


public struct ActionMappingReducer<R : Reducer, F : Function> : Reducer where F.Output == R.Action {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let f : F
    
    @usableFromInline
    init(r: R, f: F) {
        self.r = r
        self.f = f
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: F.Input) -> R.SideEffect? {
        r.apply(to: &state, action: f(action))
    }
    
}


public struct ActionLensingReducer<R : Reducer, L : Lens> : Reducer where L.PartialState == R.Action {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let l : L
    
    @usableFromInline
    init(r: R, l: L) {
        self.r = r
        self.l = l
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: L.WholeState) -> R.SideEffect? {
        r.apply(to: &state, action: l.get(from: action))
    }
    
}


public struct ActionFlatMappingReducer<R : Reducer, F : Function> where F.Output == R.Action? {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let f : F
    
    @usableFromInline
    init(r: R, f: F) {
        self.r = r
        self.f = f
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: F.Input) -> R.SideEffect? {
        f(action)
            .flatMap{action in r.apply(to: &state, action: action)}
    }
}


public struct ActionPrismingReducer<R : Reducer, P : Prism> where P.PartialState == R.Action {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let p : P
    
    @usableFromInline
    init(r: R, p: P) {
        self.r = r
        self.p = p
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: P.WholeState) -> R.SideEffect? {
        p.tryGet(from: action)
            .flatMap{action in r.apply(to: &state, action: action)}
    }
}
