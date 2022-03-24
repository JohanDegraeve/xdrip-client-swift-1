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
    
    public var providesBLEHeartbeat: Bool = true
    
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
    
    /// - instance of bluetoothTransmitter that will connect to the CGM, with goal to achieve heartbeat mechanism,  nothing else
    /// - if nil then there's no heartbeat generated
    private var bluetoothTransmitter: BluetoothTransmitter?
    
    /// for use in trace
    private let categoryxDripCGMManager      =        "xDripCGMManager               "

    public init() {
        
        // see if bluetoothTransmitter needs to be instantiated
        bluetoothTransmitter = setupBluetoothTransmitter()
        
    }
    
    public required convenience init?(rawState: RawStateValue) {
        self.init()
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        
        // check if bluetoothTransmitter is still valid - used for heartbeating
        checkCGMBluetoothTransmitter()
        
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
    
    /// check if a new bluetoothTransmitter needs to be assigned and if yes, assign it
    private func checkCGMBluetoothTransmitter() {
        
        if UserDefaults.standard.cgmTransmitterDeviceAddress != sharedUserDefaults.cgmTransmitterDeviceAddress {
            
            // assign new bluetoothTransmitter. If return value is nil, and if it was not nil before, and if it was currently connected then it will disconnect automatically, because there's no other reference to it, hence deinit will be called
            bluetoothTransmitter = setupBluetoothTransmitter()
            
            // assign local copy of cgmTransmitterDeviceAddress to the value stored in sharedUserDefaults (possibly nil value)
            UserDefaults.standard.cgmTransmitterDeviceAddress = sharedUserDefaults.cgmTransmitterDeviceAddress

        }
        
    }
    
    /// if sharedUserDefaults.cgmTransmitterDeviceAddress  then create new BluetoothTransmitter
    private func setupBluetoothTransmitter() -> BluetoothTransmitter? {
        
        // if sharedUserDefaults.cgmTransmitterDeviceAddress is not nil then, create a new bluetoothTranmsitter instance
        if let cgmTransmitterDeviceAddress = sharedUserDefaults.cgmTransmitterDeviceAddress {
            
            // unwrap cgmTransmitter_CBUUID_Service and cgmTransmitter_CBUUID_Receive
            if let cgmTransmitter_CBUUID_Service = sharedUserDefaults.cgmTransmitter_CBUUID_Service, let cgmTransmitter_CBUUID_Receive = sharedUserDefaults.cgmTransmitter_CBUUID_Receive {

                // a new cgm transmitter has been setup in xDrip4iOS
                // we will connect to the same transmitter here so it can be used as heartbeat
                let newBluetoothTransmitter = BluetoothTransmitter(deviceAddress: cgmTransmitterDeviceAddress, servicesCBUUID: cgmTransmitter_CBUUID_Service, CBUUID_Receive: cgmTransmitter_CBUUID_Receive)
                
                return newBluetoothTransmitter

            } else {
                
                trace("in checkCGMBluetoothTransmitter, looks like a coding error, xdrip4iOS did set a value for cgmTransmitterDeviceAddress in sharedUserDefaults but did not set a value for cgmTransmitter_CBUUID_Service or cgmTransmitter_CBUUID_Receive", category: categoryxDripCGMManager)
                
                return nil
                
            }
            
        }
        
        return nil

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

// add cgmTransmitterDeviceAddress to UserDefaults
// this is the local stored (ie not shared with xDrip4iOS) copy of the cgm (bluetooth) device address
extension UserDefaults {
    
    private enum Key: String {
        /// used as local copy of cgmTransmitterDeviceAddress, will be compared regularly against value in shared UserDefaults
        case cgmTransmitterDeviceAddress = "com.loopkit.Loop.cgmTransmitterDeviceAddress"
    }

    public var cgmTransmitterDeviceAddress: String? {
        get {
            return string(forKey: Key.cgmTransmitterDeviceAddress.rawValue)
        }
        set {
            set(newValue, forKey: Key.cgmTransmitterDeviceAddress.rawValue)
        }
    }
    
}

