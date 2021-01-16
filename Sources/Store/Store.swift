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
    
    private(set) public var state : State
    
    public weak var delegate : StoreDelegate?
    
    @usableFromInline
    var _dispatch : Dispatch?
    
    public init<R : Reducer, M : Middleware, Delegate: StoreDelegate>(
        initialState: R.State,
        reducer: R,
        environment: Environment,
        delegate: Delegate,
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


public extension DefaultStore {
    
    @inlinable
    func dispatch(_ action: DynamicAction) {
        DispatchQueue.main.async{[weak self] in
            self?.delegate?.storeWillChangeState()
            _ = self?._dispatch?.dispatch(action)
        }
    }
    
}


extension DefaultStore : ChangeAcceptor {
    
    @usableFromInline
    func dispatch<C : EffectfulChange>(change: C) -> [DynamicEffect] where C.State == State {
        change.apply(to: &state)
    }
    
}
