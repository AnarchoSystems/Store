//
//  StoreStub.swift
//  
//
//  Created by Markus Pfeifer on 19.12.20.
//

import Foundation



public struct StoreStub<State, Action> {
    
    @usableFromInline
    let _dispatch : (Action) -> Void
    
    @usableFromInline
    let _getState : () -> State?
    
    @usableFromInline
    init(_ dispatch: @escaping (Action) -> Void,
         _ getstate: @escaping () -> State?) {
        self._dispatch = dispatch
        self._getState = getstate
    }
    
    @inlinable
    public var state : State? {
        _getState()
    }
    
    @inlinable
    public func dispatch(action: Action) -> Void{
        _dispatch(action)
    }
    
    
}


public enum StoreKey<State, Action> : EnvironmentKey {
    
    public static var defaultValue: StoreStub<State, Action>{
        StoreStub({_ in }, {nil})
    }
    
}


public extension Environment {
    
    func getStore() -> StoreStub<State, Action>? {
        self[StoreKey<State, Action>.self]
    }
    
}
