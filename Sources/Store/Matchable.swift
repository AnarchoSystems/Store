//
//  Matchable.swift
//  
//
//  Created by Markus Pfeifer on 15.01.21.
//

import Foundation


public struct MatchablePrism<Base : Matchable, Value> : TryGetPutPrism {
    
    @usableFromInline
    let pattern : (Value) -> Base
    
    @inlinable
    public init(_ type: Base.Type = Base.self,
                pattern: @escaping (Value) -> Base) {
        self.pattern = pattern
    }
    
    @inlinable
    public func apply<T>(to whole: inout Base, change: (inout Value) -> T) -> T? {
        whole.mutate(ifMatching: pattern, change: change)
    }
    
    @inlinable
    public func tryGet(from whole: Base) -> Value? {
        whole[pattern]
    }
    
    @inlinable
    public func put(in whole: inout Base, newValue: Value) {
        whole = pattern(newValue)
    }
    
    
    func aspect<NewBase : Matchable>(of nextPattern: @escaping (Base) -> NewBase) -> MatchablePrism<NewBase, Value> {
        MatchablePrism<NewBase, Value>{value in nextPattern(pattern(value))}
    }
    
    static func ..<NewBase>(lhs: Self, rhs: @escaping (Base) -> NewBase) -> MatchablePrism<NewBase, Value> {
        lhs.aspect(of: rhs)
    }
    
}


extension Optional : EfficientMutateMatchable {
    public mutating func prepareForMutation() {
        self = nil
    }
}

extension Result : Matchable{}


public protocol Matchable {
    mutating func mutate<Value,T>(ifMatching pattern: (Value) -> Self,
                                  change: (inout Value) -> T) -> T?
}


public extension Matchable {
    
    func matches<Value>(pattern: (Value) -> Self) -> Bool {
        tryGet(type: Value.self).flatMap
        {path, value in
            pattern(value).tryGet(type: Value.self).map
            {otherPath, _ in
                path == otherPath
            }
        } ?? false
    }
    
    subscript<Value>(pattern: (Value) -> Self) -> Value? {
        guard
            let (path, value) = tryGet(type: Value.self),
            let (patternPath, _) = pattern(value).tryGet(type: Value.self),
            path == patternPath else {
            return nil
        }
        return value
    }
    
    mutating func mutate<Value,T>(ifMatching pattern: (Value) -> Self,
                                  change: (inout Value) -> T) -> T? {
        guard var value = self[pattern] else {
            return nil
        }
        defer {
            self = pattern(value)
        }
        return change(&value)
    }
    
}


public protocol EfficientMutateMatchable : Matchable {
    mutating func prepareForMutation()
}

public extension EfficientMutateMatchable {
    
    mutating func mutate<Value,T>(ifMatching pattern: (Value) -> Self,
                                  change: (inout Value) -> T) -> T? {
        guard var value = self[pattern] else {
            return nil
        }
        prepareForMutation()
        defer {
            self = pattern(value)
        }
        return change(&value)
    }
    
}

private extension Matchable {
    
    func tryGet<Value>(type: Value.Type) -> ([String?], Value)? {
        
        var path = [String?]()
        var matchable : Any = self
        var mirror = Mirror(reflecting: matchable)
        
        while displayStyleOK(mirror: mirror),
              let (label, child) = mirror.children.first {
            path.append(label)
            if let value = child as? Value {
                return (path, value)
            }
            matchable = child
            mirror = Mirror(reflecting: matchable)
        }
        return nil
        
    }
    
}


private func displayStyleOK(mirror: Mirror) -> Bool {
    #if DEBUG
    return mirror.displayStyle == .enum
    #else
    return true
    #endif
}
