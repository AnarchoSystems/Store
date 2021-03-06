//
//  OpticsCompositions.swift
//  
//
//  Created by Markus Pfeifer on 21.12.20.
//

import Foundation


public extension Lens {
    
    @inlinable
    static func ..<O : Lens>(lhs: Self, rhs: O) -> ComposedLens<Self, O> where O.WholeState == PartialState {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    static func ..<P : Prism>(lhs: Self, rhs: P) -> LensPrism<Self, P> where PartialState == P.WholeState {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Lens>(with other: O) -> ComposedLens<Self, O> where PartialState == O.WholeState {
        ComposedLens(l1: self, l2: other)
    }
    
    @inlinable
    func compose<P : Prism>(with prism: P) -> LensPrism<Self, P> where PartialState == P.WholeState {
        LensPrism(l: self, p: prism)
    }
    
}


public extension Prism {
    
    @inlinable
    static func ..<O : Prism>(lhs: Self, rhs: O) -> ComposedPrism<Self, O> where O.MaybePartialState == WholeState {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    static func ..<L : Lens>(lhs: Self, rhs: L) -> PrismLens<Self, L> where L.WholeState == MaybePartialState {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : Prism>(with other: O) -> ComposedPrism<Self, O> where O.MaybePartialState == WholeState {
        ComposedPrism(p1: self, p2: other)
    }
    
    @inlinable
    func compose<L : Lens>(with lens: L) -> PrismLens<Self, L> where L.WholeState == MaybePartialState {
        PrismLens(l: lens, p: self)
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


public struct ComposedLens<L1 : Lens, L2 : Lens> : Lens where L1.PartialState == L2.WholeState {
    
    @usableFromInline
    let l1 : L1
    @usableFromInline
    let l2 : L2
    
    @usableFromInline
    init(l1: L1, l2: L2){(self.l1, self.l2) = (l1, l2)}
    
    @inlinable
    public func apply<T>(to whole: inout L1.WholeState,
                         change: (inout L2.PartialState) -> T) -> T {
        l1.apply(to: &whole){partial in
            l2.apply(to: &partial, change: change)
        }
    }
    
}


extension ComposedLens : GetSetLens where L1 : GetSetLens, L2 : GetSetLens {
    
    public func get(from whole: L1.WholeState) -> L2.PartialState {
        l2.get(from: l1.get(from: whole))
    }
    
    public func set(in whole: inout L1.WholeState,
                    newValue: L2.PartialState) {
        l1.apply(to: &whole) {part in
            l2.set(in: &part, newValue: newValue)
        }
    }
    
}


public struct ComposedPrism<P1 : Prism, P2 : Prism> : Prism where P1.WholeState == P2.MaybePartialState {
   
    @usableFromInline
    let p1 : P1
    @usableFromInline
    let p2 : P2
    
    @usableFromInline
    init(p1 : P1, p2 : P2){(self.p1, self.p2) = (p1, p2)}
    
    @inlinable
    public func apply<T>(to whole: inout P2.WholeState,
                         change: (inout P1.MaybePartialState) -> T) -> T? {
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


public struct LensPrism<L : Lens, P : Prism> : Prism where L.PartialState == P.WholeState {
    
    @usableFromInline
    let l : L
    @usableFromInline
    let p : P
    
    @usableFromInline
    init(l: L, p: P){(self.l, self.p) = (l, p)}
    
    @inlinable
    public func apply<T>(to whole: inout L.WholeState, change: (inout P.MaybePartialState) -> T) -> T? {
        l.apply(to: &whole){part in
            p.apply(to: &part, change: change)
        }
    }
    
}


public struct PrismLens<P : Prism, L : Lens> where P.MaybePartialState == L.WholeState {
    
    @usableFromInline
    let l : L
    @usableFromInline
    let p : P
    
    @usableFromInline
    init(l: L, p: P){(self.l, self.p) = (l, p)}
    
    @inlinable
    public func apply<T>(to whole: inout P.WholeState, change: (inout L.PartialState) -> T) -> T? {
        p.apply(to: &whole){part in
            l.apply(to: &part, change: change)
        }
    }
    
}

public extension Downcast {
    
    @inlinable
    func withFallback<O : Downcast>(_ fallback: O) -> OrCast<Self, O> where O.SubType == SubType, O.SuperType == SuperType {
        OrCast(c1: self, c2: fallback)
    }
    
    @inlinable
    static func ||<O : Downcast>(lhs: Self, rhs: O) -> OrCast<Self, O> where O.SubType == SubType, O.SuperType == SuperType {
        lhs.withFallback(rhs)
    }
    
}

public struct OrCast<C1 : Downcast, C2 : Downcast> : Downcast where C1.SuperType == C2.SuperType, C1.SubType == C2.SubType {
    
    @usableFromInline
    let c1 : C1
    @usableFromInline
    let c2 : C2
    
    @usableFromInline
    init(c1: C1, c2: C2){(self.c1, self.c2) = (c1, c2)}
    
    @inlinable
    public func downCast(_ object: C1.SuperType) -> C1.SubType? {
        c1.downCast(object) ?? c2.downCast(object)
    }
    
}
