//
//  ComposeMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 19.12.20.
//

import Foundation


extension Middleware {
    
    @inlinable
    static func ..<O : Middleware>(lhs: Self, rhs: O) -> ComposedMiddleware<Self, O> where NewDispatch == O.BaseDispatch {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Middleware>(with other: O) -> ComposedMiddleware<Self, O> where NewDispatch == O.BaseDispatch {
        ComposedMiddleware(m1: self, m2: other)
    }
    
}


public struct ComposedMiddleware<M1 : Middleware, M2 : Middleware> : Middleware where M1.State == M2.State, M1.NewDispatch == M2.BaseDispatch{
    
    let m1 : M1
    let m2 : M2
    
    @usableFromInline
    init(m1: M1, m2: M2){(self.m1, self.m2) = (m1, m2)}
    
    public func apply(to dispatchFunction: M1.BaseDispatch,
                      environment: Environment<M1.State, M1.BaseDispatch.Action>) -> M2.NewDispatch {
        m2.apply(to: m1.apply(to: dispatchFunction,
                              environment: environment),
                 environment: environment)
    }
    
}
