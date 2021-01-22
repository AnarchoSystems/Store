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
    
    public init<R : DependentReducer, M : Middleware>(
        initialState: R.Implementation.State,
        reducer: R,
        environment: Dependencies = Dependencies(),
        middleware: M)
    where R.Implementation.State == State, M.BaseDispatch == BaseDispatch<R.Implementation>, M.NewDispatch == Dispatch, M.State == State {
        
        self.state = initialState
        
        let baseDispatch = BaseDispatch(r: reducer.inject(from: environment),
                                        acceptor: self)
        
        self._dispatch = middleware
            .apply(to: baseDispatch,
                   store: stub(),
                   environment: environment)
    }
    
}

public extension CombineStore {
    
    @inlinable
    func dispatch<Action : DynamicAction>(_ action: Action) {
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
