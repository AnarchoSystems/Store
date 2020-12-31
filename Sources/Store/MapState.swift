//
//  MapState.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation



public extension Reducer {
    
    @inlinable
    func mapState<Arrow: Lens>(_ lens: Arrow) -> StateLensingReducer<Self, Arrow> where Arrow.PartialState == State {
        StateLensingReducer(r: self, arrow: lens)
    }
    
    @inlinable
    func mapState<Arrow : Prism>(_ prism: Arrow) -> StatePrismingReducter<Self, Arrow> where Arrow.MaybePartialState == State {
        StatePrismingReducter(r: self, arrow: prism)
    }
    
}


public struct StateLensingReducer<R : Reducer, Arrow : Lens> : Reducer where Arrow.PartialState == R.State {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let arrow : Arrow
    
    @usableFromInline
    init(r: R, arrow: Arrow) {
        self.r = r
        self.arrow = arrow
    }
    
    @inlinable
    public func apply(to state: inout Arrow.WholeState, action: R.Action) -> R.SideEffect? {
        arrow.apply(to: &state) {part in
            r.apply(to: &part, action: action)
        }
    }
    
}


public struct StatePrismingReducter<R : Reducer, Arrow : Prism> : Reducer where Arrow.MaybePartialState == R.State {
    
    @usableFromInline
    let r : R
    @usableFromInline
    let arrow : Arrow
    
    @usableFromInline
    init(r: R, arrow: Arrow) {
        self.r = r
        self.arrow = arrow
    }
    
    @inlinable
    public func apply(to state: inout Arrow.WholeState, action: R.Action) -> R.SideEffect? {
        arrow.apply(to: &state) {part in
            r.apply(to: &part, action: action)
        }.flatMap{$0}
    }
    
}
