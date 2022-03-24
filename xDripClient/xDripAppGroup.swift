//
//  xDripAppGroup.swift
//  xDripClient
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Randall Knutson. All rights reserved.
//

import LoopKit
import HealthKit
import Combine


public class xDripAppGroup {
    
    private enum AppGroupError: Error {
        case data(reason: String)
    }

    private let sharedUserDefaults: UserDefaults?
    
    public var latestReadings: AnyPublisher<[xDripReading], Swift.Error> {
        return sharedUserDefaults.publisher.retry(2).tryMap { try self.fetchLatestReadings($0) }
            .map { $0.filter { $0.isStateValid } }.eraseToAnyPublisher()
    }
    
    /// the mac address of the cgm to which xDrip4iOS is connecting. Nil if none defined
    /// - set by xdrip4ios. xDripClient will need to read it regularly to check if it has changed
    public var cgmTransmitterDeviceAddress: String? {
        
        if let cGMTransmitterAddress = sharedUserDefaults?.string(forKey: "cgmTransmitterDeviceAddress") {
            return cGMTransmitterAddress
        } else {
            return nil
        }
        
    }
    
    /// the service uuid to discover, see description cgmTransmitterDeviceAddress
    public var cgmTransmitter_CBUUID_Service: String? {
        
        if let cgmTransmitter_CBUUID_Service = sharedUserDefaults?.string(forKey: "cgmTransmitter_CBUUID_Service") {
            return cgmTransmitter_CBUUID_Service
        } else {
            return nil
        }
        
    }
    
    /// the receive characteristic to subscribe too,  see description cgmTransmitterDeviceAddress
    public var cgmTransmitter_CBUUID_Receive: String? {
        
        if let cgmTransmitter_CBUUID_Receive = sharedUserDefaults?.string(forKey: "cgmTransmitter_CBUUID_Receive") {
            return cgmTransmitter_CBUUID_Receive
        } else {
            return nil
        }
        
    }
    
    public init(_ group: String? = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String) {
        sharedUserDefaults = UserDefaults.init(suiteName: group)
    }
    
    private func fetchLatestReadings(_ sharedUserDefaults: UserDefaults? ) throws -> Array<xDripReading> {
        guard let encodedLatestReadings = sharedUserDefaults?.data(forKey: "latestReadings") else {
            throw AppGroupError.data(reason: "Couldn't fetch latest readings from xDrip4iOS.")
        }
        
        let decodedLatestReadings = try? JSONSerialization.jsonObject(with: encodedLatestReadings, options: [])
        guard let latestReadings = decodedLatestReadings as? Array<AnyObject> else {
            throw AppGroupError.data(reason: "Couldn't decode latest readings from xDrip4iOS.")
        }
        
        var transformedReadings: Array<xDripReading> = []
        for reading in latestReadings {
            var glucoseTrendType: GlucoseTrend?
            if let rawGlucoseTrendType = reading["Trend"] as? Int {
                glucoseTrendType = GlucoseTrend(rawValue: rawGlucoseTrendType)
            }
            
            var glucoseValue: HKQuantity?
            if let rawGlucoseValue = reading["Value"] as? Double {
                glucoseValue = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: rawGlucoseValue)
            }
            
            var glucoseStartDate: Date?
            if let rawGlucoseStartDate = reading["DT"] as? String {
                glucoseStartDate = try self.parseTimestamp(rawGlucoseStartDate)
            }
            
            if let trend = glucoseTrendType, let glucose = glucoseValue, let datetime = glucoseStartDate {
                let reading = xDripReading(trendType: trend, quantity: glucose, startDate: datetime)
                transformedReadings.append(reading)
            }
        }
        return transformedReadings
    }
    
    private func parseTimestamp(_ timestamp: String) throws -> Date? {
        let regex = try NSRegularExpression(pattern: "\\((.*)\\)")
        if let match = regex.firstMatch(in: timestamp, range: NSMakeRange(0, timestamp.count)) {
            let epoch = Double((timestamp as NSString).substring(with: match.range(at: 1)))! / 1000
            return Date(timeIntervalSince1970: epoch)
        }
        return nil
    }
}
