//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 19.12.20.
//

import Foundation


public protocol EnvironmentKey {
    associatedtype Value
}


public struct Dependencies {
    
    @usableFromInline
    var dict : [String : Any] = [:]
    
    @inlinable
    public init(){}
    
    
    @inlinable
    public subscript<Key : EnvironmentKey>(_ key: Key.Type) -> Key.Value? {
        get{
            dict[String(describing: key)] as? Key.Value
        }
        set{
            guard let value = newValue else {
                dict.removeValue(forKey: String(describing: key))
                return
            }
            dict[String(describing: key)] = value
        }
    }
    
}


public extension DependentReducer {
    
    func environmentValue<L : Lens>(
        _ lens: L,
        value: L.PartialState
    ) -> InjectingReducer<L, Self> where L.WholeState == Dependencies {
        InjectingReducer(body: self, lens: lens, value: value)
    }
    
}



public struct InjectingReducer<L: Lens, R : DependentReducer> : ReducerWrapper where L.WholeState == Dependencies {
    public typealias Implementation = R.Implementation
    
    
    public let body : R
    @usableFromInline
    let lens : L
    @usableFromInline
    let value : L.PartialState
    
    @inlinable
    public func inject(from environment: Dependencies) -> R.Implementation {
        var environment = environment
        lens.apply(to: &environment, change: {$0 = value})
        return body.inject(from: environment)
    }
    
}



public extension Middleware {
    
    @inlinable
    func environmentValue<L : Lens>(_ value: L.PartialState,
                             for lens: L) -> InjectingMiddleware<Self, L>
    where L.WholeState == Dependencies
    {
            InjectingMiddleware(base: self,
                                lens: lens,
                                value: value)
    }
    
}


public struct InjectingMiddleware<Base : Middleware, L : GetSetLens> : Middleware where L.WholeState == Dependencies {
    
    @usableFromInline
    let base : Base
    @usableFromInline
    let lens : L
    @usableFromInline
    let value : L.PartialState
    
    @usableFromInline
    init(base: Base,
         lens: L,
         value: L.PartialState) {
        (self.base, self.lens, self.value) = (base, lens, value)
    }
    
    @inlinable
    public func apply(to dispatchFunction: Base.BaseDispatch,
                      store: StoreStub<Base.State>,
                      environment: Dependencies) -> Base.NewDispatch {
        var env = environment
        lens.set(in: &env, newValue: value)
        return base.apply(to: dispatchFunction,
                          store: store,
                          environment: env)
    }
    
}
