//
//  Reducer.swift
//  
//
//  Created by Markus Pfeifer on 09.12.20.
//

import Foundation


public protocol Reducer {
    
    associatedtype State
    
    func apply(to state: inout State, action: DynamicAction) -> [DynamicEffect]
    
}

public typealias ErasedReducer = Reducer


public protocol ReducerWrapper : ErasedReducer where State == Body.State {
    
    associatedtype Body : ErasedReducer
    
    var body : Body {get}
    
}


public extension ReducerWrapper {
    
    func apply(to state: inout Body.State, action: DynamicAction) -> [DynamicEffect] {
        body.apply(to: &state, action: action)
    }
    
}


public protocol PureReducer : ReducerWrapper where PureState == State {
    
    associatedtype PureState
    func apply(to state: inout PureState, action: DynamicAction)
    
}


public extension PureReducer {
    
    @inlinable
    var body: PureReducerBody<Self>{
        PureReducerBody(wrapped: self)
    }
    
}


public struct PureReducerBody<R : PureReducer> : ErasedReducer {
    
    @usableFromInline
    let wrapped : R
    
    @usableFromInline
    init(wrapped: R){
        self.wrapped = wrapped
    }
    
    public func apply(to state: inout R.State, action: DynamicAction) -> [DynamicEffect] {
        wrapped.apply(to: &state, action: action)
        return []
    }
    
}
