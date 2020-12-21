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
    
    func embedAction<E : Embedding>(_ embedding: E) -> ActionEmbeddingReducer<Self, E> where E.SubType == Action {
        ActionEmbeddingReducer(r: self, e: embedding)
    }
    
    func flatMapAction<F : Function>(_ transform: F) -> ActionFlatMappingReducer<Self, F> where F.Output == Action? {
        ActionFlatMappingReducer(r: self, f: transform)
    }
    
    func flatMapAction<NewAction>(_ transform: @escaping (NewAction) -> Action?) -> ActionFlatMappingReducer<Self, Closure<NewAction, Action?>> {
        ActionFlatMappingReducer(r: self, f: Closure(transform))
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


public struct ActionEmbeddingReducer<R : Reducer, E : Embedding> where E.SubType == R.Action {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let e : E
    
    @usableFromInline
    init(r: R, e: E) {
        self.r = r
        self.e = e
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: E.SuperType) -> R.SideEffect? {
        e.downCast(action)
            .flatMap{action in r.apply(to: &state, action: action)}
    }
}
