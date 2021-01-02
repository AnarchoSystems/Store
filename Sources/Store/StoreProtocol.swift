//
//  StoreProtocol.swift
//  
//
//  Created by Markus Pfeifer on 02.01.21.
//

import Foundation


public protocol StoreProtocol {
    
    associatedtype State
    associatedtype Action
    
    var state : State{get}
    func dispatch(_ action: Action)
    
}


public extension StoreProtocol where Self : AnyObject {
    
    @inlinable
    func stub() -> StoreStub<State, Action> {
        StoreStub(self)
    }
    
}


public struct StoreStub<State, Action> : StoreProtocol {
    
    @usableFromInline
    let store : ErasedStore<State, Action>
    
    @inlinable
    public init<Store : StoreProtocol & AnyObject>(_ store: Store) where Store.State == State, Store.Action == Action {
        self.store = ConcreteStore(base: store)
    }
    
    @inlinable
    public var state: State {
        store.state
    }
    
    @inlinable
    public func dispatch(_ action: Action) {
        store.dispatch(action)
    }
    
}


@usableFromInline
internal class ErasedStore<State, Action> : StoreProtocol {
    
    @usableFromInline
    var state : State {
        fatalError("Abstract")
    }
    
    @usableFromInline
    func dispatch(_ action: Action) {
        fatalError("Abstract")
    }
    
}


@usableFromInline
internal final class ConcreteStore<Base : StoreProtocol & AnyObject> : ErasedStore<Base.State, Base.Action> {
    
    @usableFromInline
    let initialState : Base.State
    @usableFromInline
    weak var base : Base?
    
    @usableFromInline
    init(base: Base) {
        self.base = base
        self.initialState = base.state
    }
    
    @usableFromInline
    override var state: Base.State {
        base?.state ?? initialState
    }
    
    @usableFromInline
    override func dispatch(_ action: Base.Action) {
        base?.dispatch(action)
    }
    
}
