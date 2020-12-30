//
//  Action.swift
//  
//
//  Created by Markus Pfeifer on 29.12.20.
//

import Foundation



public protocol DynamicAction {}


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


public extension Reducer where Action : DynamicAction {
    
    @inlinable
    func eraseAction() -> ActionEmbeddingReducer<Self, ActionCast<Action>> {
        ActionEmbeddingReducer(r: self, e: ActionCast())
    }
    
}
