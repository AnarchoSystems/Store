//
//  Initable.swift
//  
//
//  Created by Markus Pfeifer on 22.01.21.
//

import Foundation


public protocol VoidInit{
    
    init()
    
}


public extension IndepentendReducerWrapper where Body : VoidInit {
    
    @inlinable
    var body : Body {
        Body()
    }
    
}

