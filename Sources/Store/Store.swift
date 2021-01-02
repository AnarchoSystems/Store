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

public typealias Store = DefaultStore

public final class DefaultStore<State, Dispatch : DispatchFunction> : StoreProtocol {
    
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
        environment: Environment,
        delegate: Delegate,
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


public extension DefaultStore {
    
    @inlinable
    func dispatch(_ action: Dispatch.Action) {
        DispatchQueue.main.async{[weak self] in
            _ = self?._dispatch?.dispatch(action)
        }
    }
    
}


extension DefaultStore : ChangeAcceptor {
    
    @usableFromInline
    func dispatch<C : EffectfulChange>(change: C) -> [Dispatch.Effect] where C.State == State, C.SideEffect == Dispatch.Effect {
        change.apply(to: &state)
    }
    
}
