//
//  ObservableMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 13.01.21.
//

import Foundation


public enum SubscribeAction {
    case subscribe
    case unsubscribe
}

public struct ObservableMiddleware<State, BaseDispatch : DispatchFunction, O : Observable, Action : DynamicAction> : Middleware {
    
    @usableFromInline
    let observable : O
    
    @usableFromInline
    let onValue : (O.Observation) -> Action
    
    @usableFromInline
    let subAction : (DynamicAction) -> SubscribeAction?
    @usableFromInline
    let subEffect : (DynamicEffect) -> SubscribeAction?
    
    @usableFromInline
    let onAction : (DynamicAction) -> ((O) -> Void)?
    @usableFromInline
    let onEffect : (DynamicEffect) -> ((O) -> Void)?
    
    @inlinable
    public init(_ observable: O,
                subscribeByAction: @escaping (DynamicAction) -> SubscribeAction? = {_ in nil},
                subscribeByEffect: @escaping (DynamicEffect) -> SubscribeAction? = {_ in nil},
                onAction: @escaping (DynamicAction) -> ((O) -> Void)? = {_ in nil},
                onEffect: @escaping (DynamicEffect) -> ((O) -> Void)? = {_ in nil},
                onSend: @escaping (O.Observation) -> Action) {
        self.observable = observable
        self.onValue = onSend
        self.subAction = subscribeByAction
        self.subEffect = subscribeByEffect
        self.onAction = onAction
        self.onEffect = onEffect
    }
    
    
    public func apply(to dispatchFunction: BaseDispatch, store: StoreStub<State>, environment: Dependencies) -> NewDispatch {
        NewDispatch(base: dispatchFunction,
                    observable: observable,
                    onValue: onValue,
                    store: store,
                    subAction: subAction,
                    subEffect: subEffect,
                    onAction: onAction,
                    onEffect: onEffect)
    }
    
    public struct NewDispatch : DispatchFunction {
        
        @usableFromInline
        var base : BaseDispatch
        @usableFromInline
        let observable : O
        
        @usableFromInline
        let onValue : (O.Observation) -> Action
        
        @usableFromInline
        let store : StoreStub<State>
        
        @usableFromInline
        let subAction : (DynamicAction) -> SubscribeAction?
        @usableFromInline
        let subEffect : (DynamicEffect) -> SubscribeAction?
        
        @usableFromInline
        let onAction : (DynamicAction) -> ((O) -> Void)?
        @usableFromInline
        let onEffect : (DynamicEffect) -> ((O) -> Void)?
        
        @usableFromInline
        var observers = 0
        
        @usableFromInline
        var cancellable : Cancellable? = nil
        
        @inlinable
        public mutating func dispatch<Action : DynamicAction>(_ action: Action) -> [DynamicEffect] {
            
            let a0 = subAction(action)
            let effects = base.dispatch(action)
            
            let selectors = effects.compactMap(onEffect) + (onAction(action).map{[$0]} ?? [])
            
            for selector in selectors {
                selector(observable)
            }
            
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


public extension ObservableMiddleware where O.Observation == Action {
    
    @inlinable
    init(_ observable: O,
                subscribeByAction: @escaping (DynamicAction) -> SubscribeAction? = {_ in nil},
                subscribeByEffect: @escaping (DynamicEffect) -> SubscribeAction? = {_ in nil},
                onAction: @escaping (DynamicAction) -> ((O) -> Void)? = {_ in nil},
                onEffect: @escaping (DynamicEffect) -> ((O) -> Void)? = {_ in nil}) {
        self.observable = observable
        self.onValue = {$0}
        self.subAction = subscribeByAction
        self.subEffect = subscribeByEffect
        self.onAction = onAction
        self.onEffect = onEffect
    }
    
}
