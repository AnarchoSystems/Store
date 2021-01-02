//
//  Action.swift
//  
//
//  Created by Markus Pfeifer on 29.12.20.
//

import Foundation



public protocol DynamicAction {}
public protocol DynamicEffect {}
public struct Nop : DynamicEffect {
    @inlinable public init(){}
}

public struct ActionCast<A : DynamicAction> : Embedding {
    
    @inlinable
    public init(){}
    
    @inlinable
    public func cast(_ object: A) -> DynamicAction {
        object
    }
    
    @inlinable
    public func downCast(_ object: DynamicAction) -> A? {
        object as? A
    }
    
}


public struct EffectCast<E : DynamicEffect> : Embedding {
    
    @inlinable
    public init(){}
    
    @inlinable
    public func cast(_ object: E) -> DynamicEffect {
        object
    }
    
    @inlinable
    public func downCast(_ object: DynamicEffect) -> E? {
        object as? E
    }
    
}


public protocol ActionRepresentable : RawRepresentable where RawValue == DynamicAction {}


public extension Reducer where Action : DynamicAction, SideEffect : DynamicEffect {
    
    @inlinable
    func erased() -> ErasedDynamicReducer<Self> {
        ErasedDynamicReducer(base: self)
    }
    
}


public extension Reducer where SideEffect : DynamicEffect {
    
    @inlinable
    func erased<Cast : Downcast>(using cast: Cast) -> DynamicReducerErasedByCast<Self, Cast> {
        DynamicReducerErasedByCast(base: self, cast: cast)
    }
    
}


public extension Reducer where SideEffect : DynamicEffect, Action : ActionRepresentable {
    
    @inlinable
    func erased() -> DynamicReducerErasedByCast<Self, RawEmbedding<Action>> {
        self.erased(using: RawEmbedding())
    }
    
}


public protocol DynamicReducer : Reducer where Self.Action == DynamicAction, Self.SideEffect == DynamicEffect {}


public struct ErasedDynamicReducer<Base : Reducer> : DynamicReducer where Base.Action : DynamicAction, Base.SideEffect : DynamicEffect {
    
    @usableFromInline
    let base : Base
    
    @usableFromInline
    init(base: Base){self.base = base}
    
    public func apply(to state: inout Base.State,
                      action: DynamicAction) -> [DynamicEffect] {
        (action as? Base.Action).map{action in
            base.apply(to: &state, action: action)
        } ?? []
    }
    
}


public struct DynamicReducerErasedByCast<Base : Reducer, Cast: Downcast> : DynamicReducer where Base.SideEffect : DynamicEffect, Cast.SuperType == DynamicAction, Cast.SubType == Base.Action {
    
    @usableFromInline
    let base : Base
    @usableFromInline
    let cast : Cast
    
    @usableFromInline
    init(base: Base, cast: Cast){
        self.base = base
        self.cast = cast
    }
    
    @inlinable
    public func apply(to state: inout Base.State, action: DynamicAction) -> [DynamicEffect] {
        cast.downCast(action).map{action in
            base.apply(to: &state, action: action)
        } ?? []
    }
    
}
