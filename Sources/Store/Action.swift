//
//  Action.swift
//  
//
//  Created by Markus Pfeifer on 29.12.20.
//

import Foundation



public protocol DynamicAction {}
public protocol DynamicEffect {}

public typealias DynamicActionCast = ActionCast 

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

public protocol ActionRepresentable {

    init?<A : DynamicAction>(action: A)

}


public struct ActionEmbedding<A : DynamicAction, R : ActionRepresentable> : Downcast {
    
    @inlinable
    public init(){}
    
    @inlinable
    public func downCast(_ object: A) -> R? {
        R(action: object)
    }
    
}
