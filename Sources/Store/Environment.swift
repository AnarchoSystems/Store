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


public struct Environment<State, Action> {
    
    private var dict : [String : Any] = [:]
    
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


public extension Middleware {
    
    func injecting<L : Lens>(_ value: L.PartialState,
                             for lens: L) -> InjectingMiddleware<Self, L>
    where L.WholeState == Environment<State, BaseDispatch.Action>
    {
            InjectingMiddleware(base: self,
                                lens: lens,
                                value: value)
    }
    
}


public struct InjectingMiddleware<Base : Middleware, L : Lens> : Middleware where L.WholeState == Environment<Base.State, Base.BaseDispatch.Action> {
    
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
                      environment: Environment<Base.State, Base.BaseDispatch.Action>) -> Base.NewDispatch {
        var env = environment
        lens.set(in: &env, newValue: value)
        return base.apply(to: dispatchFunction,
                          environment: env)
    }
    
}
