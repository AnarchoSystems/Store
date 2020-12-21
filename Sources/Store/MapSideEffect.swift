//
//  MapSideEffect.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public extension Reducer {
    
    @inlinable
    func mapSideEffect<F : Function>(_ transform: F) -> SideEffectMappingReducer<Self, F> where F.Input == SideEffect {
        SideEffectMappingReducer(r: self, map: transform)
    }
    
    @inlinable
    func mapSideEffect<NewEffect>(_ transform: @escaping (SideEffect) -> NewEffect) -> SideEffectMappingReducer<Self, Closure<SideEffect, NewEffect>> {
        SideEffectMappingReducer(r: self, map: Closure(transform))
    }
    
    @inlinable
    func flatMapSideEffect<F : Function, NewEffect>(_ transform: F) -> SideEffectFlatMappingReducer<Self, F, NewEffect> where F.Input == SideEffect, F.Output == NewEffect? {
        SideEffectFlatMappingReducer(r: self, flatMap: transform)
    }
    
    @inlinable
    func mapSideEffect<NewEffect>(_ transform: @escaping (SideEffect) -> NewEffect?) -> SideEffectFlatMappingReducer<Self, Closure<SideEffect, NewEffect?>, NewEffect> {
        SideEffectFlatMappingReducer(r: self, flatMap: Closure(transform))
    }
    
    @inlinable
    func mapSideEffect<NewEffect>(newType: NewEffect.Type = NewEffect.self) -> PureReducerSideEffectEmbedder<Self, NewEffect> where SideEffect == Void {
        PureReducerSideEffectEmbedder(r: self)
    }
    
}


public struct SideEffectMappingReducer<R : Reducer, Map : Function> : Reducer where Map.Input == R.SideEffect {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let map : Map
    
    @usableFromInline
    init(r: R, map: Map){
        self.r = r
        self.map = map
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: R.Action) -> Map.Output? {
        r.apply(to: &state, action: action).map(map.callAsFunction)
    }
    
}


public struct SideEffectFlatMappingReducer<R : Reducer, FlatMap : Function, NewEffect> : Reducer where FlatMap.Input == R.SideEffect, FlatMap.Output == NewEffect? {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let flatMap : FlatMap
    
    @usableFromInline
    init(r: R, flatMap: FlatMap){
        self.r = r
        self.flatMap = flatMap
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: R.Action) -> NewEffect? {
        r.apply(to: &state, action: action).flatMap(flatMap.callAsFunction)
    }
    
}


public struct PureReducerSideEffectEmbedder<R : Reducer, NewEffect> : Reducer where R.SideEffect == Void {
    
    @usableFromInline
    let r : R
    
    @usableFromInline
    init(r: R){
        self.r = r
    }
    
    @inlinable
    public func apply(to state: inout R.State, action: R.Action) -> NewEffect? {
        r.apply(to: &state, action: action)
        return nil
    }
    
}
