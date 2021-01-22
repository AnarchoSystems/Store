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
    
    public init<R : DependentReducer, M : Middleware, Delegate: StoreDelegate>(
        initialState: R.Implementation.State,
        reducer: R,
        environment: Dependencies,
        delegate: Delegate,
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


public extension DefaultStore {
    
    @inlinable
    func dispatch<Action : DynamicAction>(_ action: Action) {
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
