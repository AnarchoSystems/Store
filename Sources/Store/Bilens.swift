//
//  Bilens.swift
//  
//
//  Created by Markus Pfeifer on 16.01.21.
//

import Foundation



public extension Lens {
    
    func paired<O : Lens>(with other: O) -> BiLens<Self, O> where O.WholeState == WholeState {
        BiLens(l1: self, l2: other)
    }
    
}



public struct Pairing<L1 : Lens, L2 : Lens> where L1.WholeState == L2.WholeState {
    
    let changeWhole : ((inout L1.WholeState) -> Void) -> Void
    
    let l1 : L1
    let l2 : L2
    
    private func _withFirst<T>(_ closure: (inout L1.PartialState) -> T) -> T {
        var result : T!
       changeWhole{whole in
           result = l1.apply(to: &whole, change: closure)
       }
       return result
   }
    
    private func _withSecond<T>(_ closure: ( inout L2.PartialState) -> T) -> T {
        var result : T!
        changeWhole{whole in
            result = l2.apply(to: &whole, change: closure)
        }
        return result
    }
    
    public var first : L1.PartialState {
        _withFirst{$0}
    }
    
    public var second : L2.PartialState {
        _withSecond{$0}
    }
    
    public mutating func withFirst<T>(_ closure: (inout L1.PartialState) -> T) -> T {
         _withFirst(closure)
    }
    
    public mutating func withSecond<T>(_ closure: ( inout L2.PartialState) -> T) -> T {
        _withSecond(closure)
    }
    
    public mutating func withBoth<T>(_ closure: (inout L1.PartialState, inout L2.PartialState) -> T) -> T {
        _withFirst{part1 in
            _withSecond{part2 in
                closure(&part1, &part2)
            }
        }
    }
    
}


public struct BiLens<L1 : Lens, L2 : Lens> : Lens where L1.WholeState == L2.WholeState {
    
    let l1 : L1
    let l2 : L2
    
    public func apply<T>(to whole: inout L1.WholeState, change: (inout Pairing<L1, L2>) -> T) -> T {
        withoutActuallyEscaping({(change : (inout L1.WholeState) -> Void) in change(&whole)})
        {changer in
            var pairing = Pairing(changeWhole: changer, l1: l1, l2: l2)
            return change(&pairing)
        }
    }
    
}
