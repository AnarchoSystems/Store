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


public final class Store<State, Dispatch : DispatchFunction> {
    
    private(set) public var state : State {
        willSet {
                self.delegate?.storeWillChangeState()
        }
    }
    
    public weak var delegate : StoreDelegate?
    
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


public extension Store {
    
    @inlinable
    func dispatch(_ action: Dispatch.Action) {
        DispatchQueue.main.async{[weak self] in
            _ = self?._dispatch?.dispatch(action)
        }
    }
    
}


public struct BaseDispatch<R : Reducer> : DispatchFunction {
    
    let r : R
    let onStateChange : ((inout R.State) -> R.SideEffect?) -> R.SideEffect?
    
    public func dispatch(_ action: R.Action) -> R.SideEffect? {
        onStateChange{state in
            r.apply(to: &state, action: action)
        }
    }
    
}
