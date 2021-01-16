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


public struct Environment {
    
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


public extension Middleware {
    
    @inlinable
    func injecting<L : Lens>(_ value: L.PartialState,
                             for lens: L) -> InjectingMiddleware<Self, L>
    where L.WholeState == Environment
    {
            InjectingMiddleware(base: self,
                                lens: lens,
                                value: value)
    }
    
}


public struct InjectingMiddleware<Base : Middleware, L : GetSetLens> : Middleware where L.WholeState == Environment {
    
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
                      environment: Environment) -> Base.NewDispatch {
        var env = environment
        lens.set(in: &env, newValue: value)
        return base.apply(to: dispatchFunction,
                          store: store,
                          environment: env)
    }
    
}
