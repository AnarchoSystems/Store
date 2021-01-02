//
//  Middleware.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public protocol DispatchFunction {
    associatedtype Action
    associatedtype Effect
    mutating func dispatch(_ action: Action) -> [Effect]
}


public protocol Middleware where BaseDispatch.Action == NewDispatch.Action, BaseDispatch.Effect == NewDispatch.Effect {
    
    associatedtype State
    associatedtype BaseDispatch : DispatchFunction
    associatedtype NewDispatch : DispatchFunction
    
    func apply(to dispatchFunction: BaseDispatch,
               store: StoreStub<State, BaseDispatch.Action>,
               environment: Environment) -> NewDispatch
    
}
