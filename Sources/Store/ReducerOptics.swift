//
//  MapState.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public protocol DetailReducer : DependentReducer where Implementation.State == StateDetail.WholeState, Body.Implementation.State == StateDetail.PartialState {
    
    associatedtype StateDetail : Lens
    associatedtype Body : DependentReducer
    
    var lens : StateDetail{get}
    var body : Body{get}
    
}

public struct DetailReducerImplementation<R : ReducerImplementation, L : Lens> : ReducerImplementation where L.PartialState == R.State {
    
    @usableFromInline
    let reducer : R
    @usableFromInline
    let lens : L
    
    @usableFromInline
    init(reducer: R, lens: L){
        (self.reducer, self.lens) = (reducer, lens)
    }
    
    @inlinable
    public func apply<Action : DynamicAction>(to state: inout L.WholeState,
                                              action: Action) -> [DynamicEffect] {
        return lens.apply(to: &state) {part in
            reducer.apply(to: &part, action: action)
        }
    }
    
}

public extension DetailReducer {
    
    @inlinable
    func inject(from environment: Dependencies) -> DetailReducerImplementation<Body.Implementation, StateDetail> {
        DetailReducerImplementation(reducer: body.inject(from: environment),
                                    lens: lens)
    }
    
}


public protocol ConditionalReducer : DependentReducer where Implementation.State == MaybeState.WholeState, Body.Implementation.State == MaybeState.MaybePartialState {
    
    associatedtype MaybeState : Prism
    associatedtype Body : DependentReducer
    
    var prism : MaybeState{get}
    var body : Body{get}
    
}


public struct ConditionalReducerImplementation<R : ReducerImplementation, P : Prism> where R.State == P.MaybePartialState {
    
    @usableFromInline
    let reducer : R
    @usableFromInline
    let prism : P
    
    @usableFromInline
    init(reducer: R, prism: P){
        (self.reducer, self.prism) = (reducer, prism)
    }
    
    @inlinable
    func apply<Action : DynamicAction>(to state: inout P.WholeState,
                                       action: Action) -> [DynamicEffect] {
        return prism.apply(to: &state) {part in
            reducer.apply(to: &part, action: action)
        } ?? []
    }
    
}


public extension ConditionalReducer {
    
    @inlinable
    func inject(from environment: Dependencies) -> ConditionalReducerImplementation<Body.Implementation, MaybeState> {
        ConditionalReducerImplementation(reducer: body.inject(from: environment),
                                         prism: prism)
    }
    
}


public protocol ActionMappingReducer : ReducerImplementation where ActionMap.SuperType : DynamicAction, ActionType == ActionMap.SubType {
    
    associatedtype ActionType
    associatedtype ActionMap : Downcast
    
    var actionMap : ActionMap{get}
    
    func apply(to state: inout State, action: ActionType) -> [DynamicEffect]
    
}


public extension ActionMappingReducer {
    
    @inlinable
    func apply<Action : DynamicAction>(to state: inout State,
                                       action: Action) -> [DynamicEffect] {
        guard
            let downcastAction = action as? ActionMap.SuperType,
            let action = actionMap.downCast(downcastAction) else {
            return []
        }
        return apply(to: &state, action: action)
    }
    
}


public protocol ActionCastingReducer : ActionMappingReducer where ActionType : DynamicAction {}


public extension ActionCastingReducer {
    
    @inlinable
    var actionMap : DynamicActionCast<ActionType> {
        DynamicActionCast()
    }
    
}


public protocol PureActionMappingReducer : ActionMappingReducer {
    
    func apply(to state: inout State, action: ActionMap.SubType)
    
}


public extension PureActionMappingReducer {
    
    @inlinable
    func apply(to state: inout State,
               action: ActionMap.SubType) -> [DynamicEffect] {
        apply(to: &state, action: action)
        return []
    }
    
}


public protocol ActionRepresentableReducer : ReducerImplementation {
    
    associatedtype ActionType : ActionRepresentable
    
    func apply(to state: inout State, action: ActionType) -> [DynamicEffect]
    
}


public extension ActionRepresentableReducer {
    
    @inlinable
    func apply<Action : DynamicAction>(to state: inout State, action: Action) -> [DynamicEffect] {
        guard let action = ActionType(action: action) else {
            return []
        }
        return apply(to: &state, action: action)
    }
    
}


public protocol PureActionRepresentableReducer : ActionRepresentableReducer {
    
    func apply(to state: inout State, action: ActionType)
    
}


public extension PureActionRepresentableReducer {
    
    @inlinable
    func apply(to state: inout State, action: ActionType) -> [DynamicEffect] {
        apply(to: &state, action: action)
        return []
    }
    
}


public struct IdentityCast<T> : Embedding {
    
    @inlinable
    public init(type: T.Type = T.self){}
    
    @inlinable
    public func downCast(_ object: T) -> T? {
        object
    }
    
    @inlinable
    public func cast(_ object: T) -> T {
        object
    }
    
}

struct IdentityLens<S> : GetSetLens {
    
    @inlinable
    public init(type: S.Type = S.self){}
    
    @inlinable
    public func apply<T>(to whole: inout S,
                         change: (inout S) -> T) -> T {
        change(&whole)
    }
    
    @inlinable
    public func get(from whole: S) -> S {
        whole
    }
    
    @inlinable
    public func set(in whole: inout S, newValue: S) {
        whole = newValue
    }
    
}


struct IdentityPrism<S> : TryGetPutPrism {
    
    
    @inlinable
    public init(type: S.Type = S.self){}
    
    @inlinable
    public func apply<T>(to whole: inout S,
                         change: (inout S) -> T) -> T? {
        change(&whole)
    }
    
    @inlinable
    public func tryGet(from whole: S) -> S? {
        whole
    }
    
    @inlinable
    public func put(in whole: inout S,
                    newValue: S) {
        whole = newValue
    }
    
}
