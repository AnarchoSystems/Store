//
//  Lensable.swift
//  
//
//  Created by Markus Pfeifer on 15.01.21.
//

import Foundation



public protocol Lensable where Lens.Base == Self {
    associatedtype Lens : Lenses = LensNameSpace<Self>
}

@dynamicMemberLookup
public protocol Lenses {
    associatedtype Base : Lensable
    static subscript<T>(dynamicMember kp: WritableKeyPath<Base, T>) -> WritableKeyPath<Base,T> { get }
}

public extension Lenses {
    static subscript<T>(dynamicMember kp: WritableKeyPath<Base, T>) -> WritableKeyPath<Base, T> {
        kp
    }
}


public enum LensNameSpace<Base : Lensable> : Lenses {}



public struct CollectionSubscriptLens<M : MutableCollection> : Lens {
    
    let index : M.Index
    
    public init(_ index: M.Index) {
        self.index = index
    }
    
    public func apply<T>(to whole: inout M,
                         change: (inout M.Element) -> T) -> T {
        change(&whole[index])
    }
    
}
