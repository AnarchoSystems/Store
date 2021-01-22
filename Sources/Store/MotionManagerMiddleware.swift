//
//  MotionManagerMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 18.01.21.
//

import Foundation


#if canImport(CoreMotion) && os(iOS)

import CoreMotion

public class Accelerometer : Observable {
    
    public typealias Observation = Result<CMAccelerometerData, Error>
    
    let mgr : CMMotionManager
    
    public init(mgr: CMMotionManager = CMMotionManager()) {
        self.mgr = mgr
    }
    
    public func setAccelerometerUpdateInterval(_ newValue : TimeInterval) {
        mgr.accelerometerUpdateInterval = newValue
    }
    
    public func subscribe<O>(observer: O) -> Cancellation where O : Observer, Result<CMAccelerometerData, Error> == O.Observation {
        mgr.startAccelerometerUpdates(to: .init())
        { (data, error) in
            observer.send(data.map(Result.success) ?? error.map(Result.failure) ?? .failure(UnknownError()))
        }
        return Cancellation(mgr: mgr)
    }
    
    public struct Cancellation : Cancellable {
        let mgr : CMMotionManager
        public func cancel() {
            mgr.stopAccelerometerUpdates()
        }
    }
    
}

#endif


struct UnknownError : Error {}
