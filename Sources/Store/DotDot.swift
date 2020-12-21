//
//  DotDot.swift
//  
//
//  Created by Markus Pfeifer on 21.12.20.
//

import Foundation


infix operator ..

@inlinable
public func ..<S,T,U>(lhs: @escaping (S) -> T,
                      rhs: @escaping (T) -> U) -> (S) -> U {
    {s in rhs(lhs(s))}
}

@inlinable
public func ..<S,T>(lhs: S,
                    rhs: (S) -> T) -> T {
    rhs(lhs)
}
