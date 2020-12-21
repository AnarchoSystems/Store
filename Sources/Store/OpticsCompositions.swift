//
//  OpticsCompositions.swift
//  
//
//  Created by Markus Pfeifer on 21.12.20.
//

import Foundation


public extension Lens {
    
    @inlinable
    static func ..<O : Lens>(lhs: Self, rhs: O) -> ComposedLens<Self, O> where O.PartialState == WholeState {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Lens>(with other: O) -> ComposedLens<Self, O> where O.PartialState == WholeState {
        ComposedLens(l1: self, l2: other)
    }
    
}


public extension Prism {
    
    @inlinable
    static func ..<O : Prism>(lhs: Self, rhs: O) -> ComposedPrism<Self, O> where O.PartialState == WholeState {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Prism>(with other: O) -> ComposedPrism<Self, O> where O.PartialState == WholeState {
        ComposedPrism(p1: self, p2: other)
    }
    
}


public extension Embedding {
    
    @inlinable
    static func ..<O : Embedding>(lhs: Self, rhs: O) -> ComposedEmbedding<Self, O> where O.SubType == SuperType {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Embedding>(with other: O) -> ComposedEmbedding<Self, O> where O.SubType == SuperType {
        ComposedEmbedding(e1: self, e2: other)
    }
    
}


public struct ComposedLens<L1 : Lens, L2 : Lens> : Lens where L1.WholeState == L2.PartialState {
    
    @usableFromInline
    let l1 : L1
    @usableFromInline
    let l2 : L2
    
    @usableFromInline
    init(l1: L1, l2: L2){(self.l1, self.l2) = (l1, l2)}
    
    @inlinable
    public func apply<T>(to whole: inout L2.WholeState,
                         change: (inout L1.PartialState) -> T) -> T {
        l2.apply(to: &whole){partial in
            l1.apply(to: &partial, change: change)
        }
    }
    
}


public struct ComposedPrism<P1 : Prism, P2 : Prism> : Prism where P1.WholeState == P2.PartialState {
   
    @usableFromInline
    let p1 : P1
    @usableFromInline
    let p2 : P2
    
    @usableFromInline
    init(p1 : P1, p2 : P2){(self.p1, self.p2) = (p1, p2)}
    
    @inlinable
    public func apply<T>(to whole: inout P2.WholeState,
                         change: (inout P1.PartialState) -> T) -> T? {
        p2.apply(to: &whole) {partial in
            p1.apply(to: &partial, change: change)
        }?.flatMap{$0}
    }
    
}


public struct ComposedEmbedding<E1 : Embedding, E2 : Embedding> : Embedding where E1.SuperType == E2.SubType {
    
    @usableFromInline
    let e1 : E1
    @usableFromInline
    let e2 : E2
    
    @usableFromInline
    init(e1: E1, e2: E2){(self.e1, self.e2) = (e1, e2)}
    
    @inlinable
    public func cast(_ object: E1.SubType) -> E2.SuperType {
        e2.cast(e1.cast(object))
    }
    
    @inlinable
    public func downCast(_ object: E2.SuperType) -> E1.SubType? {
        e2.downCast(object).flatMap(e1.downCast)
    }
    
}