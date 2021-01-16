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
    
    private(set) public var state : State
    
    @usableFromInline
    var _dispatch : Dispatch?
    
    public init<R : Reducer, M : Middleware>(
        initialState: R.State,
        reducer: R,
        environment: Environment = Environment(),
        middleware: M)
    where R.State == State, M.BaseDispatch == BaseDispatch<R>, M.NewDispatch == Dispatch, M.State == State {
        
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
    func dispatch(_ action: DynamicAction) {
        DispatchQueue.main.async{[weak self] in
            self?.objectWillChange.send()
            _ = self?._dispatch?.dispatch(action)
        }
    }
    
}


extension CombineStore : ChangeAcceptor {
    
    @usableFromInline
    func dispatch<C : EffectfulChange>(change: C) -> [DynamicEffect] where C.State == State {
        change.apply(to: &state)
    }
    
}


#endif
