//
//  xDripStatusModel.swift
//  xDripClientUI
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import xDripClient
import LoopKit
import LoopKitUI
import HealthKit


class xDripStatusModel: NSObject, ObservableObject {
    
    let cgmManager: xDripCGMManager
    let glucoseUnitObservable: DisplayGlucoseUnitObservable
    var hasCompleted: (() -> Void)?
    
    var preferredUnit: HKUnit {
        return glucoseUnitObservable.displayGlucoseUnit
    }
    
    var latestReading: xDripReading? {
        return cgmManager.latestReading
    }
    
    lazy var unitFormatter: QuantityFormatter = {
        let formatter = QuantityFormatter()
        formatter.setPreferredNumberFormatter(for: preferredUnit)
        return formatter
    }()

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    init(cgmManager: xDripCGMManager, for glucoseUnitObservable: DisplayGlucoseUnitObservable) {
        self.cgmManager = cgmManager
        self.glucoseUnitObservable = glucoseUnitObservable
    }
    
    func notifyDeletion() {
        cgmManager.notifyDelegateOfDeletion {
            DispatchQueue.main.async { self.hasCompleted?() }
        }
    }
}
