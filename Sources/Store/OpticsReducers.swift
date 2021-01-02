//
//  OpticsReducers.swift
//  
//
//  Created by Markus Pfeifer on 30.12.20.
//

import Foundation



public protocol LensReducer : Reducer {
    
    associatedtype StateLens : Lens
    
    var stateLens : StateLens{get}
    
    func apply(to part: inout StateLens.PartialState, action: Action) -> SideEffect?
    
}


public extension LensReducer {
    
    func apply(to state: inout StateLens.WholeState, action: Action) -> SideEffect? {
        stateLens.apply(to: &state){partialState in
            apply(to: &partialState, action: action)
        }
    }
    
}


public protocol PureLensReducer : LensReducer where SideEffect == Void {
    
    func apply(to part: inout StateLens.PartialState, action: Action)
    
}


public extension PureLensReducer {
    
    func apply(to part: inout StateLens.PartialState, action: Action) -> Void? {
        apply(to: &part, action: action)
    }
    
}


public protocol PrismReducer : Reducer {
        
    associatedtype StatePrism : Prism
    
    var statePrism : StatePrism{get}
    
    func apply(to part: inout StatePrism.MaybePartialState, action: Action) -> SideEffect?
    
}


public extension PrismReducer {
    
    func apply(to state: inout StatePrism.WholeState, action: Action) -> SideEffect? {
        statePrism.apply(to: &state){partialState in
            apply(to: &partialState, action: action)
        }.flatMap{$0}
    }
    
}


public protocol PurePrismReducer : PrismReducer where SideEffect == Void {
    
    func apply(to part: inout StatePrism.MaybePartialState, action: Action)
    
}


public extension PurePrismReducer {
    
    func apply(to part: inout StatePrism.MaybePartialState, action: Action) -> Void? {
        apply(to: &part, action: action)
    }
    
}


public protocol StateArrowReducer : Reducer {
    
    associatedtype StateMap : StateArrow
    
    var stateMap : StateMap{get}
    
    func apply(to part: inout StateMap.State, action: Action) -> [StateMap.Effect]
    
}


public extension StateArrowReducer {
    
    func apply(to state: inout StateMap.NewState, action: Action) -> [StateMap.NewEffect] {
        stateMap.apply(to: &state){partialState in
            apply(to: &partialState, action: action)
        }
    }
    
}


public protocol PureStateArrowReducer : StateArrowReducer where SideEffect == Void, StateMap.NewEffect == Void {
    
    func apply(to part: inout StateMap.State, pureAction: Action)
    
}


public extension PureStateArrowReducer {
    
    func apply(to part: inout StateMap.State, action: Action) -> StateMap.NewEffect? {
        apply(to: &part, pureAction: action)
    }
    
}
