//
//  PublishMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 20.12.20.
//

import Foundation

#if canImport(Combine)
import Combine

public final class CombineStore<State, Dispatch : DispatchFunction> : ObservableObject {
    
    private(set) public var state : State {
        willSet {
            objectWillChange.send()
        }
    }
    
    @usableFromInline
    var _dispatch : Dispatch?
    
    public init<R : Reducer, M : Middleware, Delegate: StoreDelegate>(
        initialState: R.State,
        reducer: R,
        delegate: Delegate,
        middleware: M)
    where R.Action == Dispatch.Action, R.State == State, R.SideEffect == Dispatch.Effect, M.BaseDispatch == BaseDispatch<R>, M.NewDispatch == Dispatch, M.State == State {
        var environment = Environment<State,R.Action>()
        
        self.state = initialState
        
        environment[StoreKey<State, R.Action>] = StoreStub({[weak self] action in
            self?.dispatch(action)
        },
        {[weak self] in
            self.map(\.state)
        })
        
        let baseDispatch = BaseDispatch(r: reducer)
        {change in
            change(&self.state)
        }
        
        self._dispatch = middleware
            .apply(to: baseDispatch,
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

#endif
