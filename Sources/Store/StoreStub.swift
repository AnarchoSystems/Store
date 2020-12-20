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
    let _getState : (@escaping (State) -> Void) -> Void
    
    @usableFromInline
    init(_ dispatch: @escaping (Action) -> Void,
         _ getstate: @escaping (@escaping (State) -> Void) -> Void) {
        self._dispatch = dispatch
        self._getState = getstate
    }
    
    @inlinable
    public func dispatch(action: Action) -> Void{
        _dispatch(action)
    }
    
    @inlinable
    public func withState(_ continuation : @escaping (State) -> Void) {
        _getState(continuation)
    }
    
}


public enum StoreKey<State, Action> : EnvironmentKey {
    
    public static var defaultValue: StoreStub<State, Action>{
        StoreStub({_ in }, {_ in })
    }
    
}


public extension Environment {
    
    func getStore() -> StoreStub<State, Action>? {
        self[StoreKey<State, Action>.self]
    }
    
}
