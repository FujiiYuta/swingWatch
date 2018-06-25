/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class is responsible for managing interactions with the interface.
 */

import WatchKit
import Foundation
import Dispatch

class InterfaceController: WKInterfaceController, WorkoutManagerDelegate {
    // MARK: Properties

    let workoutManager = WorkoutManager()
    var active = false
    var forehandCount = 0
    var backhandCount = 0

    // MARK: Interface Properties
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var backhandCountLabel: WKInterfaceLabel!
    @IBOutlet weak var forehandCountLabel: WKInterfaceLabel!

    // MARK: Initialization
    
    override init() {
        super.init()
        
        workoutManager.delegate = self
    }

    // MARK: WKInterfaceController
    
    override func willActivate() {
        super.willActivate()
        active = true

        // On re-activation, update with the cached values.
        updateLabels()
    }

    override func didDeactivate() {
        super.didDeactivate()
        active = false
    }

    // MARK: Interface Bindings
    
    @IBAction func start() {
        titleLabel.setText("Workout started")
        workoutManager.startWorkout()
    }

    @IBAction func stop() {
        titleLabel.setText("Workout stopped")
        workoutManager.stopWorkout()
    }

    // MARK: WorkoutManagerDelegate
    
    func didUpdateForehandSwingCount(_ manager: WorkoutManager, forehandCount: Int) {
        /// Serialize the property access and UI updates on the main queue.
        DispatchQueue.main.async {
            self.forehandCount = forehandCount
            self.updateLabels()
        }
    }

    func didUpdateBackhandSwingCount(_ manager: WorkoutManager, backhandCount: Int) {
        /// Serialize the property access and UI updates on the main queue.
        DispatchQueue.main.async {
            self.backhandCount = backhandCount
            self.updateLabels()
        }
    }

    // MARK: Convenience
    
    func updateLabels() {
        if active {
            forehandCountLabel.setText("\(forehandCount)")
            backhandCountLabel.setText("\(backhandCount)")
        }
    }

}
