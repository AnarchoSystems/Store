//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 09.12.20.
//

import Foundation


public protocol Reducer {
    
    associatedtype SideEffect
    associatedtype State
    associatedtype Action
    
    func apply(to state: inout State, action: Action) -> SideEffect?
    
}


public protocol PureReducer : Reducer where SideEffect == Void {
    
    func apply(to state: inout State, action: Action)
    
}


public extension PureReducer {
    
    @inlinable
    func apply(to state: inout State, action: Action) -> Void? {
        apply(to: &state, action: action)
    }
    
}
