//
//  Middleware.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public protocol DispatchFunction {
    mutating func dispatch<Action : DynamicAction>(_ action: Action) -> [DynamicEffect]
}


public protocol Middleware {
    
    associatedtype State
    associatedtype BaseDispatch : DispatchFunction
    associatedtype NewDispatch : DispatchFunction
    
    func apply(to dispatchFunction: BaseDispatch,
               store: StoreStub<State>,
               environment: Dependencies) -> NewDispatch
    
}
