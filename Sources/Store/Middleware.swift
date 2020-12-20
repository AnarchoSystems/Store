//
//  Middleware.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public protocol Middleware {
    
    associatedtype State
    associatedtype Action
    associatedtype Effect
    
    func apply(to dispatchFunction: @escaping (Action) -> Effect?,
               environment: Environment<State, Action>) -> (Action) -> Effect?
    
}
