//
//  BaseDispatch.swift
//  
//
//  Created by Markus Pfeifer on 02.01.21.
//

import Foundation

@usableFromInline
internal protocol EffectfulChange {
    associatedtype State
    func apply(to state: inout State) -> [DynamicEffect]
}

@usableFromInline
internal protocol ChangeAcceptor : AnyObject {
    associatedtype State
    func dispatch<C : EffectfulChange>(change: C) -> [DynamicEffect] where C.State == State
}


public struct BaseDispatch<R : Reducer> : DispatchFunction {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let acceptor : AnyChangeAcceptor<R.State>
    
    @usableFromInline
    init<Acceptor : ChangeAcceptor>(r: R,
                                    acceptor : Acceptor) where Acceptor.State == R.State {
        self.r = r
        self.acceptor = ChangeAcceptorWrapper(base: acceptor)
    }
    
    @inlinable
    public func dispatch(_ action: DynamicAction) -> [DynamicEffect] {
        acceptor.dispatch(change: ReducerChange(r: r, action: action))
    }
    
}


@usableFromInline
internal struct ReducerChange<R : Reducer> : EffectfulChange {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let action : DynamicAction
    
    @usableFromInline
    init(r: R, action: DynamicAction){self.r = r; self.action = action}
    
    @usableFromInline
    func apply(to state: inout R.State) -> [DynamicEffect] {
        r.apply(to: &state, action: action)
    }
    
}


@usableFromInline
class AnyChangeAcceptor<State> : ChangeAcceptor {
    
    @usableFromInline
    func dispatch<C : EffectfulChange>(change: C) -> [DynamicEffect] where C.State == State {
        fatalError("Abstract")
    }
    
}


@usableFromInline
final class ChangeAcceptorWrapper<Base : ChangeAcceptor> : AnyChangeAcceptor<Base.State> {
    
    @usableFromInline
    weak var base : Base?
    
    @usableFromInline
    init(base: Base){
        self.base = base
    }
    
    @usableFromInline
    override func dispatch<C : EffectfulChange>(change: C) -> [DynamicEffect] where C.State == Base.State {
        base?.dispatch(change: change) ?? []
    }
    
}
