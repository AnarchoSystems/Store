//
//  ScanObservable.swift
//  
//
//  Created by Markus Pfeifer on 13.01.21.
//

import Foundation

public enum ScanSemantics {
    case WatchAlways
    case WatchOnlyWhenObserved(reset: Bool)
}

public final class ScanObservable<Base : Observable, NewState> : ObservedValue<NewState> {
    
    let base : Base
    let reduce : (inout NewState, Base.Observation) -> Void
    let semantics : ScanSemantics
    let seed : NewState
    var c : Cancellable?
    
    init(base: Base,
         reduce: @escaping (inout NewState, Base.Observation) -> Void,
         semantics: ScanSemantics,
         seed: NewState) {
        self.base = base
        self.reduce = reduce
        self.semantics = semantics
        self.seed = seed
        super.init(seed)
        if case .WatchAlways = semantics {
            c = base.bind(self, selector: ScanObservable.send)
        }
    }
    
    deinit {
        c?()
    }
    
    private func send(newValue: Base.Observation) {
        guard c != nil else {return}
        mutate{state in
            self.reduce(&state, newValue)
        }
    }
    
    public override func onSubscribersCountChange(oldCount: Int,
                                                  newCount: Int) {
        guard case .WatchOnlyWhenObserved(let reset) = semantics else {
            return
        }
        if oldCount == 0, newCount > 0 {
            c = base.bind(self, selector: ScanObservable.send)
        }
        else if oldCount > 0, newCount == 0 {
            c?()
            c = nil
            if reset {
                mutate{$0 = self.seed}
            }
        }
    }
    
}
