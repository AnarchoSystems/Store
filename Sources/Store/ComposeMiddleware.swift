//
//  ComposeMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 19.12.20.
//

import Foundation


public extension Middleware {
    
    func combine<O : Middleware>(with other: O) -> ComposedMiddleware<Self, O> where Action == O.Action, Effect == O.Effect {
        ComposedMiddleware(m1: self, m2: other)
    }
    
}


public struct ComposedMiddleware<M1 : Middleware, M2 : Middleware> : Middleware where M1.State == M2.State, M1.Action == M2.Action, M1.Effect == M2.Effect {
    
    let m1 : M1
    let m2 : M2
    
    public func apply(to dispatchFunction: @escaping (M1.Action) -> M1.Effect?,
                      environment: Environment<M1.State, M1.Action>) -> (M1.Action) -> M1.Effect? {
        m2.apply(to: m1.apply(to: dispatchFunction, environment: environment), environment: environment)
    }
    
}
