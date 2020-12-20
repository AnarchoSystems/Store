//
//  Environment.swift
//  
//
//  Created by Markus Pfeifer on 19.12.20.
//

import Foundation


public protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue : Value {get}
}


public struct Environment<State, Action> {
    
    private var dict : [String : Any] = [:]
    
    public subscript<Key : EnvironmentKey>(_ key: Key.Type) -> Key.Value? {
        get{
            dict[String(describing: key)] as? Key.Value
        }
        set{
            guard let value = newValue else {
                dict.removeValue(forKey: String(describing: key))
                return
            }
            dict[String(describing: key)] = value
        }
    }
    
}
