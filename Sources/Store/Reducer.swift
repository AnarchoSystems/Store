//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 09.12.20.
//

import Foundation


public protocol DependentReducer {
    
    associatedtype Implementation : ReducerImplementation
    
    func inject(from environment: Dependencies) -> Implementation
    
}


public protocol ReducerImplementation {
    
    associatedtype State
    
    func apply<Action : DynamicAction>(to state: inout State,
                                       action: Action) -> [DynamicEffect]
    
}





public protocol ReducerWrapper : DependentReducer where Body.Implementation == Implementation {
    
    associatedtype Body : DependentReducer
    
    var body : Body {get}
    
}


public extension ReducerWrapper {
    
    @inlinable
    func inject(from environment: Dependencies) -> Body.Implementation {
        body.inject(from: environment)
    }
    
}


public protocol IndepentendReducerWrapper {
    
    associatedtype Body : ReducerImplementation
    var body : Body{get}
    
}


public extension IndepentendReducerWrapper {
    
    @inlinable
    func inject(from environment: Dependencies) -> Body {
        body
    }
    
}


public protocol Reducer : DependentReducer {
    
    associatedtype State
    associatedtype Action : DynamicAction
    
    func apply(to state: inout State, action: Action) -> [DynamicEffect]
    
    
}


public extension Reducer {
    
    @inlinable
    func inject(from environment: Dependencies) -> Impl<Self> {
        Impl(reducer: self)
    }
    
}


public struct Impl<R : Reducer> : ReducerImplementation {
    
    @usableFromInline
    let reducer : R
    
    @usableFromInline
    init(reducer: R){
        self.reducer = reducer
    }
    
    @inlinable
    public func apply<Action : DynamicAction>(to state: inout R.State, action: Action) -> [DynamicEffect] {
        guard let action = action as? R.Action else {
            return []
        }
        return reducer.apply(to: &state, action: action)
    }
    
}


public protocol PureReducer : Reducer where PureState == State {
    
    associatedtype PureState
    func apply(to state: inout PureState, action: Action)
    
}


public extension PureReducer {
    
    @inlinable
    func apply(to state: inout PureState, action: DynamicAction) -> [DynamicEffect] {
        guard let action = action as? Action else {
            return []
        }
        apply(to: &state, action: action)
        return []
    }
    
}
