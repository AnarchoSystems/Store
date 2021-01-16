//
//  MapState.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation


public protocol DetailReducer : Reducer where State == StateDetail.WholeState, Body.State == StateDetail.PartialState {
    
    associatedtype StateDetail : Lens
    associatedtype Body : Reducer
    
    var lens : StateDetail{get}
    var body : Body{get}
    
}


public extension DetailReducer {
    
    @inlinable
    func apply(to state: inout StateDetail.WholeState,
               action: DynamicAction) -> [DynamicEffect] {
        return lens.apply(to: &state) {part in
            body.apply(to: &part, action: action)
        }
    }
    
}


public protocol ConditionalReducer : Reducer where State == MaybeState.WholeState, Body.State == MaybeState.MaybePartialState {
    
    associatedtype MaybeState : Prism
    associatedtype Body : Reducer
    
    var prism : MaybeState{get}
    var body : Body{get}
    
}


public extension ConditionalReducer {
    
    @inlinable
    func apply(to state: inout MaybeState.WholeState,
               action: DynamicAction) -> [DynamicEffect] {
        return prism.apply(to: &state) {part in
            body.apply(to: &part, action: action)
        } ?? []
    }
    
}


public protocol ActionMappingReducer : Reducer where ActionMap.SuperType == DynamicAction, ActionType == ActionMap.SubType {
    
    associatedtype ActionType
    associatedtype ActionMap : Downcast
    
    var actionMap : ActionMap{get}
    
    func apply(to state: inout State, action: ActionType) -> [DynamicEffect]
    
}


public extension ActionMappingReducer {
    
    @inlinable
    func apply(to state: inout State,
               action: DynamicAction) -> [DynamicEffect] {
        guard let action = actionMap.downCast(action) else {
            return []
        }
        return apply(to: &state, action: action)
    }
    
}


public protocol ActionCastingReducer : ActionMappingReducer where ActionType : DynamicAction {}


public extension ActionCastingReducer {
    
    var actionMap : DynamicActionCast<ActionType> {
        DynamicActionCast()
    }
    
}

public protocol ActionCataReducer : ActionMappingReducer where ActionType : ActionRepresentable {}

public extension ActionCataReducer {
    
    var actionMap : RawEmbedding<ActionType> {
        RawEmbedding()
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
