//
//  AnonymousMapState.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public extension Reducer {
    
    @inlinable
    func mapState<Arrow : StateArrow>(_ arrow: Arrow) -> AnonymousStateMap<Self, Arrow> where Arrow.State == State, Arrow.Effect == SideEffect {
        AnonymousStateMap(r: self, arrow: arrow)
    }
    
    @inlinable
    func mapState<NewState, NewEffect>(_ arrow: @escaping (inout NewState, (inout State) -> SideEffect?) -> NewEffect?) -> AnonymousStateMap<Self, ClosureStateArrow<State, NewState, SideEffect, NewEffect>> {
        AnonymousStateMap(r: self, arrow: ClosureStateArrow(arrow))
    }
    
}

public protocol StateArrow {
    
    associatedtype State
    associatedtype NewState
    associatedtype Effect
    associatedtype NewEffect = Effect
    
    func apply(to state: inout NewState, change: (inout State) -> Effect?) -> NewEffect?
    
}


public typealias ClosureStateArrow = MapState
public typealias PureMapState<NewState, State> = MapState<NewState, State, Void, Void> 


public struct MapState<NewState, State, Effect, NewEffect> : StateArrow {
    
    @usableFromInline
    let closure : (inout NewState, (inout State) -> Effect?) -> NewEffect?
    
    @inlinable
    public init(_ closure: @escaping (inout NewState, (inout State) -> Effect?) -> NewEffect?) {
        self.closure = closure
    }
    
    public func apply(to state: inout NewState,
                      change: (inout State) -> Effect?) -> NewEffect? {
        closure(&state, change)
    }
    
}

public struct AnonymousStateMap<R : Reducer, Arrow : StateArrow> : Reducer where Arrow.Effect == R.SideEffect, Arrow.State == R.State {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let arrow : Arrow
    
    @usableFromInline
    init(r: R,
         arrow: Arrow) {
        self.r = r
        self.arrow = arrow
    }
    
    @inlinable
    public func apply(to state: inout Arrow.NewState, action: R.Action) -> Arrow.NewEffect? {
        arrow.apply(to: &state){part in r.apply(to: &part, action: action)}
    }
    
}
