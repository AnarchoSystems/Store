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
    associatedtype SideEffect
    func apply(to state: inout State) -> [SideEffect]
}

@usableFromInline
internal protocol ChangeAcceptor : AnyObject {
    associatedtype State
    associatedtype SideEffect
    func dispatch<C : EffectfulChange>(change: C) -> [SideEffect] where C.State == State, C.SideEffect == SideEffect
}


public struct BaseDispatch<R : Reducer> : DispatchFunction {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let acceptor : AnyChangeAcceptor<R.State, R.SideEffect>
    
    @usableFromInline
    init<Acceptor : ChangeAcceptor>(r: R,
                                    acceptor : Acceptor) where Acceptor.State == R.State, Acceptor.SideEffect == R.SideEffect {
        self.r = r
        self.acceptor = ChangeAcceptorWrapper(base: acceptor)
    }
    
    @inlinable
    public func dispatch(_ action: R.Action) -> [R.SideEffect] {
        acceptor.dispatch(change: ReducerChange(r: r, action: action))
    }
    
}


@usableFromInline
internal struct ReducerChange<R : Reducer> : EffectfulChange {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let action : R.Action
    
    @usableFromInline
    init(r: R, action: R.Action){self.r = r; self.action = action}
    
    @usableFromInline
    func apply(to state: inout R.State) -> [R.SideEffect] {
        r.apply(to: &state, action: action)
    }
    
}


@usableFromInline
class AnyChangeAcceptor<State, SideEffect> : ChangeAcceptor {
    
    @usableFromInline
    func dispatch<C : EffectfulChange>(change: C) -> [SideEffect] where C.State == State, C.SideEffect == SideEffect {
        fatalError("Abstract")
    }
    
}


@usableFromInline
final class ChangeAcceptorWrapper<Base : ChangeAcceptor> : AnyChangeAcceptor<Base.State, Base.SideEffect> {
    
    @usableFromInline
    weak var base : Base?
    
    @usableFromInline
    init(base: Base){
        self.base = base
    }
    
    @usableFromInline
    override func dispatch<C : EffectfulChange>(change: C) -> [Base.SideEffect] where C.State == Base.State, C.SideEffect == Base.SideEffect {
        base?.dispatch(change: change) ?? []
    }
    
}
