/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the CoreMotion interactions and 
         provides a delegate to indicate changes in data.
 */

import Foundation
import CoreMotion
import WatchKit

/**
 `MotionManagerDelegate` exists to inform delegates of motion changes.
 These contexts can be used to enable application specific behavior.
 */
protocol MotionManagerDelegate: class {
    func didUpdateForehandSwingCount(_ manager: MotionManager, forehandCount: Int)
    func didUpdateBackhandSwingCount(_ manager: MotionManager, backhandCount: Int)
}

class MotionManager {
    // MARK: Properties
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let wristLocationIsLeft = WKInterfaceDevice.current().wristLocation == .left

    // MARK: Application Specific Constants
    
    // These constants were derived from data and should be further tuned for your needs.
    let yawThreshold = 1.95 // Radians
    let rateThreshold = 5.5	// Radians/sec
    let resetThreshold = 5.5 * 0.05 // To avoid double counting on the return swing.

    // The app is using 50hz data and the buffer is going to hold 1s worth of data.
    let sampleInterval = 1.0 / 50
    let rateAlongGravityBuffer = RunningBuffer(size: 50)
    
    weak var delegate: MotionManagerDelegate?

    /// Swing counts.
    var forehandCount = 0
    var backhandCount = 0

    var recentDetection = false

    // MARK: Initialization
    
    init() {
        // Serial queue for sample handling and calculations.
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
    }

    // MARK: Motion Manager

    func startUpdates() {
        if !motionManager.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }

        // Reset everything when we start.
        resetAllState()

        motionManager.deviceMotionUpdateInterval = sampleInterval
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }

            if deviceMotion != nil {
                self.processDeviceMotion(deviceMotion!)
            }
        }
    }

    func stopUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    // MARK: Motion Processing
    
    func processDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        let gravity = deviceMotion.gravity
        let rotationRate = deviceMotion.rotationRate

        let rateAlongGravity = rotationRate.x * gravity.x // r⃗ · ĝ
                             + rotationRate.y * gravity.y
                             + rotationRate.z * gravity.z
        rateAlongGravityBuffer.addSample(rateAlongGravity)

        if !rateAlongGravityBuffer.isFull() {
            return
        }

        let accumulatedYawRot = rateAlongGravityBuffer.sum() * sampleInterval
        let peakRate = accumulatedYawRot > 0 ?
            rateAlongGravityBuffer.max() : rateAlongGravityBuffer.min()

        if (accumulatedYawRot < -yawThreshold && peakRate < -rateThreshold) {
            // Counter clockwise swing.
            if (wristLocationIsLeft) {
                incrementBackhandCountAndUpdateDelegate()
            } else {
                incrementForehandCountAndUpdateDelegate()
            }
        } else if (accumulatedYawRot > yawThreshold && peakRate > rateThreshold) {
            // Clockwise swing.
            if (wristLocationIsLeft) {
                incrementForehandCountAndUpdateDelegate()
            } else {
                incrementBackhandCountAndUpdateDelegate()
            }
        }

        // Reset after letting the rate settle to catch the return swing.
        if (recentDetection && abs(rateAlongGravityBuffer.recentMean()) < resetThreshold) {
            recentDetection = false
            rateAlongGravityBuffer.reset()
        }
    }

    // MARK: Data and Delegate Management
    
    func resetAllState() {
        rateAlongGravityBuffer.reset()

        forehandCount = 0
        backhandCount = 0
        recentDetection = false

        updateForehandSwingDelegate()
        updateBackhandSwingDelegate()
    }

    func incrementForehandCountAndUpdateDelegate() {
        if (!recentDetection) {
            forehandCount += 1
            recentDetection = true

            print("Forehand swing. Count: \(forehandCount)")
            updateForehandSwingDelegate()
        }
    }

    func incrementBackhandCountAndUpdateDelegate() {
        if (!recentDetection) {
            backhandCount += 1
            recentDetection = true

            print("Backhand swing. Count: \(backhandCount)")
            updateBackhandSwingDelegate()
        }
    }

    func updateForehandSwingDelegate() {
        delegate?.didUpdateForehandSwingCount(self, forehandCount:forehandCount)
    }

    func updateBackhandSwingDelegate() {
        delegate?.didUpdateBackhandSwingCount(self, backhandCount:backhandCount)
    }
}
