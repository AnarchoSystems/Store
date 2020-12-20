//
//  Store.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public protocol StoreDelegate : AnyObject {
    func storeWillChangeState()
}


public final class Store<State, Action, Effect> {
    
    private(set) public var state : State {
        willSet {
                self.delegate?.storeWillChangeState()
        }
    }
    
    public weak var delegate : StoreDelegate?
    
    @usableFromInline
    var _dispatch : ((Action) -> Effect?)?
    
    public init<R : Reducer, M : Middleware, Delegate: StoreDelegate>(
        initialState: R.State,
        reducer: R,
        delegate: Delegate,
        middleware: M)
    where R.Action == Action, R.State == State, R.SideEffect == Effect, M.Action == Action, M.Effect == Effect, M.State == State {
        var environment = Environment<State,Action>()
        
        self.state = initialState
        
        environment[StoreKey<State, Action>] = StoreStub({[weak self] action in
            self?.dispatch(action)
        },
        {continuation in
            DispatchQueue.main.async{[weak self] in
                if let self = self {
                    continuation(self.state)
                }
            }
        })
        
        let baseDispatch : (Action) -> Effect? = {action in
            return reducer.apply(to: &self.state, action: action)
        }
        
        self._dispatch = middleware
            .apply(to: baseDispatch,
                   environment: environment)
    }
    
}


public extension Store {
    
    @inlinable
    func dispatch(_ action: Action) {
        DispatchQueue.main.async{[weak self] in
            _ = self?._dispatch?(action)
        }
    }
    
}
