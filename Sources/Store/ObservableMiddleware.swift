//
//  ObservableMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 13.01.21.
//

import Foundation


public enum SubscribeAction : DynamicAction {
    case subscribe
    case unsubscribe
}

public struct ObservableMiddleware<State, BaseDispatch : DispatchFunction, O : Observable> : Middleware {
    
    @usableFromInline
    let observable : O
    
    @usableFromInline
    let onValue : (O.Observation) -> DynamicAction
    
    @usableFromInline
    let subAction : (DynamicAction) -> SubscribeAction?
    @usableFromInline
    let subEffect : (DynamicEffect) -> SubscribeAction?
    
    
    @inlinable
    public init(_ observable: O,
                onAction: @escaping (DynamicAction) -> SubscribeAction? = {_ in nil},
                onEffect: @escaping (DynamicEffect) -> SubscribeAction? = {_ in nil},
                onSend: @escaping (O.Observation) -> DynamicAction) {
        self.observable = observable
        self.onValue = onSend
        self.subAction = onAction
        self.subEffect = onEffect
    }
    
    
    public func apply(to dispatchFunction: BaseDispatch, store: StoreStub<State>, environment: Environment) -> NewDispatch {
        NewDispatch(base: dispatchFunction,
                    observable: observable,
                    onValue: onValue,
                    store: store,
                    subAction: subAction,
                    subEffect: subEffect)
    }
    
    public struct NewDispatch : DispatchFunction {
        
        @usableFromInline
        var base : BaseDispatch
        @usableFromInline
        let observable : O
        
        @usableFromInline
        let onValue : (O.Observation) -> DynamicAction
        
        @usableFromInline
        let store : StoreStub<State>
        
        @usableFromInline
        let subAction : (DynamicAction) -> SubscribeAction?
        @usableFromInline
        let subEffect : (DynamicEffect) -> SubscribeAction?
        
        @usableFromInline
        var observers = 0
        
        @usableFromInline
        var cancellable : Cancellable? = nil
        
        @inlinable
        public mutating func dispatch(_ action: DynamicAction) -> [DynamicEffect] {
            
            let a0 = subAction(action)
            let effects = base.dispatch(action)
            
            let oldValue = observers
            
            interpret(a0)
            for eff in effects {
                interpret(subEffect(eff))
            }
            
            if oldValue == 0, observers > 0 {
                subscribe()
            }
            else if oldValue > 0, observers == 0 {
                unsubscribe()
            }
            
            return effects
            
        }
        
        @inlinable
        mutating func interpret(_ subAction: SubscribeAction?) {
            switch subAction {
            case .none:
                ()
            case .subscribe?:
                observers += 1
            case .unsubscribe?:
                observers -= 1
            }
        }
        
        @inlinable
        mutating func subscribe(){
            let onValue = self.onValue
            let store = self.store
            self.cancellable = observable.subscribe{o in
                store.dispatch(onValue(o))
            }
        }
        
        @inlinable
        mutating func unsubscribe(){
            cancellable?.cancel()
        }
        
    }
    
}


public extension ObservableMiddleware where DynamicAction == O.Observation {
    
    @inlinable
    init(_ observable: O,
                onAction: @escaping (DynamicAction) -> SubscribeAction? = {_ in nil},
                onEffect: @escaping (DynamicEffect) -> SubscribeAction? = {_ in nil}) {
        self.observable = observable
        self.onValue = {$0}
        self.subAction = onAction
        self.subEffect = onEffect
    }
    
}
