//
//  CombineStore.swift
//  
//
//  Created by Markus Pfeifer on 20.12.20.
//

import Foundation

#if canImport(Combine)
import Combine

public final class CombineStore<State, Dispatch : DispatchFunction> : ObservableObject, StoreProtocol {
    
    private(set) public var state : State {
        willSet {
            objectWillChange.send()
        }
    }
    
    @usableFromInline
    var _dispatch : Dispatch?
    
    public init<R : Reducer, M : Middleware>(
        initialState: R.State,
        reducer: R,
        environment: Environment = Environment(),
        middleware: M)
    where R.Action == Dispatch.Action, R.State == State, R.SideEffect == Dispatch.Effect, M.BaseDispatch == BaseDispatch<R>, M.NewDispatch == Dispatch, M.State == State {
        
        self.state = initialState
        
        let baseDispatch = BaseDispatch(r: reducer,
                                        acceptor: self)
        
        self._dispatch = middleware
            .apply(to: baseDispatch,
                   store: stub(),
                   environment: environment)
    }
    
}

public extension CombineStore {
    
    @inlinable
    func dispatch(_ action: Dispatch.Action) {
        DispatchQueue.main.async{[weak self] in
            _ = self?._dispatch?.dispatch(action)
        }
    }
    
}


extension CombineStore : ChangeAcceptor {
    
    @usableFromInline
    func dispatch<C : EffectfulChange>(change: C) -> [Dispatch.Effect] where C.State == State, C.SideEffect == Dispatch.Effect {
        change.apply(to: &state)
    }
    
}


#endif
