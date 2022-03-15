//
//  xDripCGMManager.swift
//  xDripClient
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import LoopKit
import LoopKitUI
import HealthKit
import Combine


public class xDripCGMManager: CGMManager {
    
    public var managerIdentifier: String = "xDripClient"
    
    public var localizedTitle: String = "xDrip4iOS"
    
    public var providesBLEHeartbeat: Bool = false
    
    public var isOnboarded: Bool = true // No distinction between created and onboarded
    
    public let shouldSyncToRemoteService = true
    
    public let appURL: URL? = URL(string: "xdripswift://")
    
    public var managedDataInterval: TimeInterval? = nil
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public private(set) var latestReading: xDripReading?
    
    public var glucoseDisplay: GlucoseDisplayable? {
        return self.latestReading
    }
    
    public let sharedUserDefaults: xDripAppGroup = xDripAppGroup()
    
    public let fetchQueue = DispatchQueue(label: "xDripCGMManager.fetchQueue")

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
    
    public var cgmManagerStatus: CGMManagerStatus {
        return CGMManagerStatus(hasValidSensorSession: true, device: nil)
    }
    
    public var rawState: CGMManager.RawStateValue {
        return [:]
    }
    
    public init() { }
    
    public required convenience init?(rawState: RawStateValue) {
        self.init()
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        fetchQueue.async {
            _ = self.sharedUserDefaults.latestReadings.sink(receiveCompletion: { status in
                switch status {
                case let .failure(error):
                    self.delegate.notify { (delegate) in delegate?.cgmManager(self, hasNew: .error(error)) }
                default: break
                }
            }, receiveValue: { readings in
                guard readings.isEmpty == false else {
                    self.delegate.notify { (delegate) in delegate?.cgmManager(self, hasNew: .noData) }
                    return
                }
                
                let startDate = self.delegate.call { (delegate) -> Date? in delegate?.startDateToFilterNewData(for: self) }
                let newGlucoseSamples = readings.filterDateRange(startDate, nil).map {
                    NewGlucoseSample(date: $0.startDate, quantity: $0.quantity,
                                     condition: nil, trend: $0.trendType, trendRate: $0.trendRate,
                                     isDisplayOnly: false, wasUserEntered: false,
                                     syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))")
                }
                
                self.delegate.notify { (delegate) in
                    delegate?.cgmManager(self, hasNew: newGlucoseSamples.isEmpty ? .noData : .newData(newGlucoseSamples))
                }

                self.latestReading = readings.max(by: { $0.startDate < $1.startDate })
            })
        }
    }
    
    public var debugDescription: String {
        return [
            "## xDripCGMManager",
            "latestReading: \(String(describing: latestReading))",
            ""
        ].joined(separator: "\n")
    }
}

// MARK: - AlertResponder implementation
extension xDripCGMManager {
    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}

// MARK: - AlertSoundVendor implementation
extension xDripCGMManager {
    public func getSoundBaseURL() -> URL? { return nil }
    public func getSounds() -> [Alert.Sound] { return [] }
}
