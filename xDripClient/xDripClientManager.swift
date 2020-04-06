//
//  xDripClientManager.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import HealthKit


public class xDripClientManager: CGMManager {
    
    public static var managerIdentifier = "xDripClient"

    public init() {
        client = xDripClient()
    }

    required convenience public init?(rawState: CGMManager.RawStateValue) {
        self.init()
    }

    public var rawState: CGMManager.RawStateValue {
        return [:]
    }

    public var client: xDripClient?
    
    public static let localizedTitle = LocalizedString("xDrip", comment: "Title for the CGMManager option")

    public let appURL: URL? = URL(string: "xdrip://")

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }
    
    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public let providesBLEHeartbeat = false

    public let shouldSyncToRemoteService = false

    public var sensorState: SensorDisplayable? {
        return latestBackfill
    }

    public let managedDataInterval: TimeInterval? = nil

    public private(set) var latestBackfill: Glucose?
    
    public var latestCollector: String? {
        if let glucose = latestBackfill, let collector = glucose.collector, collector != "unknown" {
            return collector
        }
        return nil
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMResult) -> Void) {
        guard let manager = client else {
            completion(.noData)
            return
        }

        // If our last glucose was less than 4.5 minutes ago, don't fetch.
        if let latestGlucose = latestBackfill, latestGlucose.startDate.timeIntervalSinceNow > -TimeInterval(minutes: 4) {
            completion(.noData)
            return
        }

        manager.fetchLast(6) { (error, glucose) in
            if let error = error {
                completion(.error(error))
                return
            }
            guard let glucose = glucose else {
                completion(.noData)
                return
            }

            // Ignore glucose values that are up to a minute newer than our previous value, to account for possible time shifting in Share data
            let startDate = self.cgmManagerDelegate?.startDateToFilterNewData(for: self)?.addingTimeInterval(TimeInterval(minutes: 1))
            
            let newGlucose = glucose.filterDateRange(startDate, nil)
            
            let newSamples = newGlucose.filter({ $0.isStateValid }).map {
                return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, isDisplayOnly: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: self.device)
            }
            
            self.latestBackfill = newGlucose.first
            
            if newSamples.count > 0 {
                completion(.newData(newSamples))
            } else {
                completion(.noData)
            }
        }
    }

    public var device: HKDevice? {
        
        return HKDevice(
            name: "xDripClient",
            manufacturer: "xDrip",
            model: latestCollector,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public var debugDescription: String {
        return [
            "## xDripClientManager",
            "latestBackfill: \(String(describing: latestBackfill))",
            "latestCollector: \(String(describing: latestCollector))",
            ""
        ].joined(separator: "\n")
    }
}
