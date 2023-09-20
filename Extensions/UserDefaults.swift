//
//  UserDefaults.swift
//  xDripClient
//
//  Created by Johan Degraeve on 13/08/2022.
//  Copyright © 2022 Randall Knutson. All rights reserved.
//

import Foundation
import LoopKit
import HealthKit

extension UserDefaults {
  
    /// using Key2 because Key already exists in xDripCGMManager
    public enum Key2: String {
    
        /// should basal be adapted depending on current bg value
        case keyForUseVariableBasal = "keyForUseVariableBasal"
        
        /// in case keyForUseVariableBasal is true, this is the percentage to be used
        case keyForPercentageVariableBasal = "keyForPercentageVariableBasal"
        
        /// will have glucose value for most recent reading, to be used in variable basal
        case keyForLatestGlucoseValue = "keyForLatestGlucoseValue"
        
        /// will have timestamp for most recent reading, to be used in variable basal
        case keyForLatestGlucoseTimeStamp = "keyForLatestGlucoseTimeStamp"
        
        case keyTimeStampStartCalculateTotalDoses = "keyTimeStampStartCalculateTotalDoses"
        
        case keyTimeStampEndCalculateTotalDoses = "keyTimeStampEndCalculateTotalDoses"
        
    }
    
    /// will have glucose value for most recent reading, to be used in variable basal
    public var latestGlucoseValue: Double {
        get {
            return double(forKey: Key2.keyForLatestGlucoseValue.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyForLatestGlucoseValue.rawValue)
        }
    }
    
    public var latestGlucoseTimeStamp: Date? {
        get {
            return object(forKey: Key2.keyForLatestGlucoseTimeStamp.rawValue) as? Date
        }
        set {
            set(newValue, forKey: Key2.keyForLatestGlucoseTimeStamp.rawValue)
        }
    }
    
    public var timeStampStartCalculateTotalDoses : Date {
        get {
            if let currentValue = object(forKey: Key2.keyTimeStampStartCalculateTotalDoses.rawValue) as? Date {
                return currentValue
            } else {
                return Date().addingTimeInterval(-3600.0*6)
            }
        }
        set {
            set(newValue, forKey: Key2.keyTimeStampStartCalculateTotalDoses.rawValue)
        }
    }
    
    public var timeStampEndCalculateTotalDoses : Date {
        get {
            if let currentValue = object(forKey: Key2.keyTimeStampEndCalculateTotalDoses.rawValue) as? Date {
                return currentValue
            } else {
                return Date().addingTimeInterval(3600.0*6)
            }
        }
        set {
            set(newValue, forKey: Key2.keyTimeStampEndCalculateTotalDoses.rawValue)
        }
    }

    /// should basal be adapted depending on current bg value
    public var useVariableBasal: Bool {

        get {
            return bool(forKey: Key2.keyForUseVariableBasal.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyForUseVariableBasal.rawValue)
        }
    }
    
    /// in case useVariableBasal is true, this is the percentage to be used - value between 0 and 100 - default 100
    public var percentageVariableBasal: Int {
        get {
            let returnValue = integer(forKey: Key2.keyForPercentageVariableBasal.rawValue)
            // if 0 set to defaultvalue
            if returnValue == 0 {
                set(100, forKey: Key2.keyForPercentageVariableBasal.rawValue)
            }

            return returnValue
        }
        set {
            set(newValue, forKey: Key2.keyForPercentageVariableBasal.rawValue)
        }
    }
    
}
