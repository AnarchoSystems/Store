//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 19.12.20.
//

import Foundation

#if canImport(Combine)
import Combine

public final class CombineStore<State, Action, Effect> : StoreDelegate, ObservableObject {
    
    var store : Store<State, Action, Effect>!
    
    public var state : State {
        store.state
    }
    
    public init<R : Reducer, M : Middleware>(
        initialState: R.State,
        reducer: R,
        middleware: M)
    where R.Action == Action, R.State == State, R.SideEffect == Effect, M.Action == Action, M.Effect == Effect, M.State == State {
        self.store = Store(initialState: initialState,
                           reducer: reducer,
                           delegate: self,
                           middleware: middleware)
    }
    
    public func storeWillChangeState() {
        objectWillChange.send()
    }
    
}


#endif
