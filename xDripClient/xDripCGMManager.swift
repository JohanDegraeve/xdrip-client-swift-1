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
import Foundation


public class xDripCGMManager: NSObject, CGMManager {
    
    public var managerIdentifier: String = "xDripClient"
    
    public var localizedTitle: String = "xDrip4iOS"
    
    public var providesBLEHeartbeat: Bool {
        get {
            return UserDefaults.standard.useCGMAsHeartbeat
        }
    }

    public var isOnboarded: Bool = true // No distinction between created and onboarded
    
    public var shouldSyncToRemoteService: Bool {
        get {
            return UserDefaults.standard.shouldSyncToRemoteService
        }
    }
    
    public let appURL: URL? = URL(string: "xdripswift://")
    
    public var managedDataInterval: TimeInterval? = nil
    
    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    
    public private(set) var latestReading: xDripReading?
    
    public var glucoseDisplay: GlucoseDisplayable? {
        return self.latestReading
    }
    
    public let sharedUserDefaults: xDripAppGroup = xDripAppGroup()
    
    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    // needed to conform to protocol CGMManager
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
    
    /// when was the last time that readings where fetched from shared userdefaults
    private var timeStampLastFetch:Date = Date(timeIntervalSince1970: 0)
    
    /// for use in trace
    private let categoryxDripCGMManager      =        "xDripClient.xDripCGMManager"

    /// define notification center, to be informed when app comes in background, so that fetchNewData can be forced
    let notificationCenter = NotificationCenter.default

    public override init() {
        
        // call super.init
        super.init()
        
        /// add observer for will enter foreground
        notificationCenter.addObserver(self, selector: #selector(runWhenAppWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // add observer for did finish launching
        notificationCenter.addObserver(self, selector: #selector(runWhenAppWillEnterForeground(_:)), name: UIApplication.didFinishLaunchingNotification, object: nil)

        // add observer for useCGMAsHeartbeat
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.Key.useCGMAsHeartbeat.rawValue, options: .new, context: nil)

        // possibly cgmTransmitterDeviceAddess in shared user defaults has been changed by xDrip4iOS while Loop was not running. Reassign the value in UserDefaults
        UserDefaults.standard.cgmTransmitterDeviceAddress = sharedUserDefaults.cgmTransmitterDeviceAddress

        // add observer for shared userdefaults key cgmTransmitterDeviceAddress
        sharedUserDefaults.sharedUserDefaults?.addObserver(self, forKeyPath: xDripAppGroup.keyForcgmTransmitterDeviceAddress, context: nil)
        
        // see if bluetoothTransmitter needs to be instantiated
        // if return value nil, then bluetoothTransmitter will be set to nil, means als if any connection would already be existing, then it will be disconnected
        bluetoothTransmitter = setupBluetoothTransmitter()
        
        // set heartbeat state text in userdefaults, this is used in the UI
        setHeartbeatStateText()
        
    }
    
    public required convenience init?(rawState: RawStateValue) {
        self.init()
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void)  {
        
        // there should be at least 1 minute between two fetches
        guard timeStampLastFetch.timeIntervalSinceNow < TimeInterval(-55.0) else {return}
        
        // check if bluetoothTransmitter is still valid - used for heartbeating
        checkCGMBluetoothTransmitter()
        
        trace("in fetchNewDataIfNeeded", category: categoryxDripCGMManager)

        timeStampLastFetch = Date()
        
        _ = self.sharedUserDefaults.latestReadings.sink(receiveCompletion: { status in
            switch status {
            case let .failure(error):
                trace("    failure occurred", category: self.categoryxDripCGMManager)
                self.delegate.notify { (delegate) in delegate?.cgmManager(self, hasNew: .error(error)) }
            default: break
            }
        }, receiveValue: { readings in
            guard readings.isEmpty == false else {
                trace("    readings.isEmpty is true", category: self.categoryxDripCGMManager)
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
            
            trace("    will iterate through readings, there are %{public}@ readings", category: self.categoryxDripCGMManager, newGlucoseSamples.count.description)
            
            for sample in newGlucoseSamples {
                // %{public}@
                trace("    sample date  %{public}@", category: self.categoryxDripCGMManager, sample.date.debugDescription)
                trace("    sample value %{public}@", category: self.categoryxDripCGMManager, sample.quantity.description)
            }
            
            self.delegate.notify { (delegate) in
                delegate?.cgmManager(self, hasNew: newGlucoseSamples.isEmpty ? .noData : .newData(newGlucoseSamples))
            }

            self.latestReading = readings.max(by: { $0.startDate < $1.startDate })
        })

    }
    
    public override var debugDescription: String {
        return [
            "## xDripCGMManager",
            "latestReading: \(String(describing: latestReading))",
            ""
        ].joined(separator: "\n")
    }
    
    // override to observe useCGMAsHeartbeat and keyForcgmTransmitterDeviceAddress
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let keyPath = keyPath {
            
            if let keyPathEnum = UserDefaults.Key(rawValue: keyPath) {
                
                switch keyPathEnum {
                    
                case UserDefaults.Key.useCGMAsHeartbeat :
                    bluetoothTransmitter = setupBluetoothTransmitter()
                    
                    setHeartbeatStateText()
                    
                default:
                    break
                }
            } else {
                
                if keyPath == xDripAppGroup.keyForcgmTransmitterDeviceAddress {
                    
                    checkCGMBluetoothTransmitter()
                    
                    setHeartbeatStateText()
                    
                }
                
            }
        }
    }

    /// will call fetchNewDataIfNeeded with completionhandler
    /// used as wakeup function
    private func fetchNewDataIfNeeded() {
        
        self.fetchNewDataIfNeeded { result in
            guard case .newData = result else { return }
            self.delegate.notify { delegate in
                delegate?.cgmManager(self, hasNew: result)
            }
        }
        
    }

    /// check if a new bluetoothTransmitter needs to be assigned and if yes, assign it
    private func checkCGMBluetoothTransmitter() {
        
        if UserDefaults.standard.cgmTransmitterDeviceAddress != sharedUserDefaults.cgmTransmitterDeviceAddress {
            
            // assign new bluetoothTransmitter. If return value is nil, and if it was not nil before, and if it was currently connected then it will disconnect automatically, because there's no other reference to it, hence deinit will be called
            bluetoothTransmitter = setupBluetoothTransmitter()
            
            // assign local copy of cgmTransmitterDeviceAddress to the value stored in sharedUserDefaults (possibly nil value)
            UserDefaults.standard.cgmTransmitterDeviceAddress = sharedUserDefaults.cgmTransmitterDeviceAddress
            
            setHeartbeatStateText()

        }
        
    }
    
    /// if UserDefaults.standard.useCGMAsHeartbeat is true and sharedUserDefaults.cgmTransmitterDeviceAddress  then create new BluetoothTransmitter
    private func setupBluetoothTransmitter() -> BluetoothTransmitter? {
        
        // if sharedUserDefaults.cgmTransmitterDeviceAddress is not nil then, create a new bluetoothTranmsitter instance
        if UserDefaults.standard.useCGMAsHeartbeat, let cgmTransmitterDeviceAddress = sharedUserDefaults.cgmTransmitterDeviceAddress {
            
            // unwrap cgmTransmitter_CBUUID_Service and cgmTransmitter_CBUUID_Receive
            if let cgmTransmitter_CBUUID_Service = sharedUserDefaults.cgmTransmitter_CBUUID_Service, let cgmTransmitter_CBUUID_Receive = sharedUserDefaults.cgmTransmitter_CBUUID_Receive {

                // a new cgm transmitter has been setup in xDrip4iOS
                // we will connect to the same transmitter here so it can be used as heartbeat
                let newBluetoothTransmitter = BluetoothTransmitter(deviceAddress: cgmTransmitterDeviceAddress, servicesCBUUID: cgmTransmitter_CBUUID_Service, CBUUID_Receive: cgmTransmitter_CBUUID_Receive, onHeartBeatStatusChange: setHeartbeatStateText, heartbeat: fetchNewDataIfNeeded)
                
                return newBluetoothTransmitter

            } else {
                
                trace("in checkCGMBluetoothTransmitter, looks like a coding error, xdrip4iOS did set a value for cgmTransmitterDeviceAddress in sharedUserDefaults but did not set a value for cgmTransmitter_CBUUID_Service or cgmTransmitter_CBUUID_Receive", category: categoryxDripCGMManager)
                
                return nil
                
            }
            
        }
        
        return nil

    }
    
    /// will set text in UserDefaults heartBeatState depending on BluetoothTransmitter status, this is then used in UI
    private func setHeartbeatStateText() {
        
        let scanning = LocalizedString("Scanning for CGM. Force close xDrip4iOS (do not disconnect but force close the app). Keep Loop running in the foreground (prevent phone lock). This text will change as soon as a first connection is made. ", comment: "This is when Loop did not yet make a first connection to the CGM. It is scanning. Need to make sure that no other app (like xDrip4iOS) is connected to the CGM")
        
        let firstConnectionMade = LocalizedString("Did connect to CGM. You can now run both xDrip4iOS and Loop. The CGM will be used as heartbeat for Loop.", comment: "Did connect to CGM. Even though it's not connected now, this state remains valid. The CGM will be used as heartbeat for Loop.")
        
        let cgmUnknown = LocalizedString("You first need to have made a successful connection between xDrip4iOS and the CGM. Force close Loop, open xDrip4iOS and make sure it's connected to the CGM. Once done, Force close xDrip4iOS (do not disconnect but force close the app), open Loop and come back to here", comment: "There hasn't been a connectin to xDrip4iOS to the CGM. First need to have a made a successful connection between xDrip4iOS and the CGM. Force close Loop, open xDrip4iOS and make sure it's connected to the CGM. Once done, Force close xDrip4iOS (do not disconnect but force close the app), open Loop and come back to here")
        
        // this is for example in case user has selected not to use the CGM as heartbeat. In that case the UI should not even show this text. Meaning normally it should never be shown
        let notapplicable = "N/A"
        
        // in case user has selected not to use cgm as heartbeat
        if !UserDefaults.standard.useCGMAsHeartbeat {
            UserDefaults.standard.heartBeatState = notapplicable
            return
        }
        
        // in case xDrip4iOS did not make a first connection to the CGM (or explicitly disconnected from the CGM)
        if UserDefaults.standard.cgmTransmitterDeviceAddress == nil {
            UserDefaults.standard.heartBeatState = cgmUnknown
            return
        }
        
        // now there should be a bluetoothTransmitter, if not there's a coding error
        guard let bluetoothTransmitter = bluetoothTransmitter else {
            UserDefaults.standard.heartBeatState = notapplicable
            return
        }

        // if peripheral in bluetoothTransmitter is still nil, then it means Loop is still scanning for the CGM, it didn't make a first connection yet
        if bluetoothTransmitter.peripheral == nil {
            UserDefaults.standard.heartBeatState = scanning
            return
        }
        
        // in all other cases, the state should be ok
        UserDefaults.standard.heartBeatState = firstConnectionMade
        
    }
    
    @objc private func runWhenAppWillEnterForeground(_ : Notification) {
        
        fetchNewDataIfNeeded()
        
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

// MARK: - UserDefaults

extension UserDefaults {
    
    public enum Key: String {
        
        /// used as local copy of cgmTransmitterDeviceAddress, will be compared regularly against value in shared UserDefaults
        ///
        /// this is the local stored (ie not shared with xDrip4iOS) copy of the cgm (bluetooth) device address
        case cgmTransmitterDeviceAddress = "com.loopkit.Loop.cgmTransmitterDeviceAddress"
        
        /// did user ask heartbeat from CGM that is used by xDrip4iOS, default false
        case useCGMAsHeartbeat = "useCGMAsHeartbeat"
        
        /// status of Loop vs CGM, this is text shown to user in UI. Text shows the status of heartbeat
        case heartBeatState = "heartBeatState"
        
        /// should Loop upload bg readings to remote service or not. Default false
        ///
        /// Used in Loop/Managers/RemoteDataServicesManager.swift, func uploadGlucoseData(to remoteDataService: RemoteDataService)namic public var shouldSyncToRemoteService: Boo
        case shouldSyncToRemoteService = "shouldSyncToRemoteService"
       
    }
    
    /// should Loop upload bg readings to remote service or not. Default false
    ///
    /// Used in Loop/Managers/RemoteDataServicesManager.swift, func uploadGlucoseData(to remoteDataService: RemoteDataService)
    @objc dynamic public var shouldSyncToRemoteService: Bool {
        
        // default value for bool in userdefaults is false
        get {
            return bool(forKey: Key.shouldSyncToRemoteService.rawValue)
        }
        set {
            set(newValue, forKey: Key.shouldSyncToRemoteService.rawValue)
        }
        
    }
    
    /// used as local copy of cgmTransmitterDeviceAddress, will be compared regularly against value in shared UserDefaults
    var cgmTransmitterDeviceAddress: String? {
        get {
            return string(forKey: Key.cgmTransmitterDeviceAddress.rawValue)
        }
        set {
            set(newValue, forKey: Key.cgmTransmitterDeviceAddress.rawValue)
        }
    }
    
    /// did user ask heartbeat from CGM that is used by xDrip4iOS, default : true
    @objc dynamic var useCGMAsHeartbeat: Bool {
        
        // default value for bool in userdefaults is false, by default we want to use heartbeat
        get {
            return bool(forKey: Key.useCGMAsHeartbeat.rawValue)
        }
        set {
            set(newValue, forKey: Key.useCGMAsHeartbeat.rawValue)
        }
        
    }
    
    /// status of Loop vs CGM, this is text shown to user in UI. Text shows the status of heartbeat
    @objc dynamic var heartBeatState: String {
        
        // default value for bool in userdefaults is false, by default we want to use heartbeat
        get {
            return string(forKey: Key.heartBeatState.rawValue) ?? ""
        }
        set {
            set(newValue, forKey: Key.heartBeatState.rawValue)
        }
        
    }
    
}

