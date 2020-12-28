//
//  Discriminators.swift
//  
//
//  Created by Markus Pfeifer on 28.12.20.
//

import Foundation



public protocol Discriminator {
    
    associatedtype Sum
    associatedtype A
    associatedtype B
    
    func cata<T>(_ object: Sum, onA : (A) -> T, onB : (B) -> T) -> T?
    
}


public struct DowncastDiscriminator<D1 : Embedding, D2 : Embedding> : Discriminator where D1.SuperType == D2.SuperType {
    
    @usableFromInline
    let d1 : D1
    @usableFromInline
    let d2 : D2
    
    @inlinable
    public init(_ d1: D1, _ d2: D2) {
        self.d1 = d1
        self.d2 = d2
    }
    
    @inlinable
    public func cata<T>(_ object: D1.SuperType, onA: (D1.SubType) -> T, onB: (D2.SubType) -> T) -> T? {
        d1.downCast(object).map(onA) ?? d2.downCast(object).map(onB)
    }
    
}
