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
    
        /// shoud manual temp basals be included in glucose effects  calculation, yes or no - default false
        case keyForAddManualTempBasals = "keyForAddManualTempBasals"
        
        /// how long to add manual temp basals, after this period keyForAddManualTempBasals will be set to false
        case keyForDurationAddManualTempBasalsInHours = "keyForDurationAddManualTempBasalsInHours"
        
        /// timestamp when keyForAddManualTempBasals was set to true
        case keyTimeStampStartAddManualTempBasals = "keyTimeStampStartAddManualTempBasals"
        
        /// should basal be adapted depending on current bg value
        case keyForUseVariableBasal = "keyForUseVariableBasal"
        
        /// in case keyForUseVariableBasal is true, this is the percentage to be used
        case keyForPercentageVariableBasal = "keyForPercentageVariableBasal"
        
        /// timestamp start of automatic basal - will be set if keyAutoBasalRunning is set to on
        case keyTimeStampStartOfAutoBasal = "keyTimeStampStartOfAutoBasal"
        
        /// is autobasal running or not
        case keyAutoBasalRunning = "keyAutoBasalRunning"
        
        /// fixed programmed temp basal rate table will be multiplied with this factor
        case keyAutoBasalMultiplier = "keyAutoBasalMultiplier"

        /// to set autobasal duration, this is actually how long can a meal impact the glucose values (not just the carbs but also the fats and/or protein)
        case keyForAutoBasalDurationInHours = "keyForAutoBasalDurationInHours"

        /// will have value of trend for the most recent reading, to be used in autobasal
        case keyForLatestGlucoseTrend = "keyForLatestGlucoseTrend"
        
        /// will have glucose value for most recent reading, to be used in autobasal
        case keyForLatestGlucoseValue = "keyForLatestGlucoseValue"
        
        /// will have timestamp for most recent reading, to be used in autobasal
        case keyForLatestGlucoseTimeStamp = "keyForLatestGlucoseTimeStamp"
        
    }
    
    /// will have glucose value for most recent reading, to be used in autobasal
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
    
    /// will have value of trend for the latest reading, to be used in autobasal
    ///      case upUpUp       = 1
    ///      case upUp         = 2
    ///      case up           = 3
    ///      case flat         = 4
    ///      case down         = 5
    ///      case downDown     = 6
    ///      case downDownDown = 7
    public var latestGlucoseTrend: Int? {
        get {
            return integer(forKey: Key2.keyForLatestGlucoseTrend.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyForLatestGlucoseTrend.rawValue)
        }
    }
    
    /// timestamp start of automatic basal
    public var timeStampStartOfAutoBasal:Date? {
        get {
            return object(forKey: Key2.keyTimeStampStartOfAutoBasal.rawValue) as? Date
        }
        set {
            set(newValue, forKey: Key2.keyTimeStampStartOfAutoBasal.rawValue)
        }
    }
    
    /// timestamp start of automatic basal
    public var timeStampStartAddManualTempBasals:Date? {
        get {
            return object(forKey: Key2.keyTimeStampStartAddManualTempBasals.rawValue) as? Date
        }
        set {
            set(newValue, forKey: Key2.keyTimeStampStartAddManualTempBasals.rawValue)
        }
    }
    
    /// is autobasal running or not
    ///
    /// if set to true, then timeStampStartOfAutoBasal is set to now - if set to false then timeStampStartOfAutoBasal is set to nil
    public var autoBasalRunning: Bool {

        get {
            return bool(forKey: Key2.keyAutoBasalRunning.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyAutoBasalRunning.rawValue)
            
            if newValue {
                timeStampStartOfAutoBasal = Date()
            }
            
        }
    }

    /// shoud manual temp basals be included in glucose effects  calculation, yes or no - default false
    public var addManualTempBasals: Bool {

        get {
            return bool(forKey: Key2.keyForAddManualTempBasals.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyForAddManualTempBasals.rawValue)
            
            // if set to true, then set also the timestamp
            if newValue {
                timeStampStartAddManualTempBasals = Date()
            }

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

    /// in case autoBasalRunning is true, this is the multiplier to be used - value between 1 and 3.9
    public var autoBasalMultiplier: Double {
        get {
            let returnValue = double(forKey: Key2.keyAutoBasalMultiplier.rawValue)
            // if 0 set to defaultvalue
            if returnValue == 0 {
                set(1.0, forKey: Key2.keyAutoBasalMultiplier.rawValue)
            }

            return returnValue
        }
        set {
            set(newValue, forKey: Key2.keyAutoBasalMultiplier.rawValue)
        }
    }

    public var autoBasalDurationInHours: Int {
        get {
            let returnValue = integer(forKey: Key2.keyForAutoBasalDurationInHours.rawValue)
            // if 0 set to default value
            if returnValue == 0 {
                set(3, forKey: Key2.keyForAutoBasalDurationInHours.rawValue)
            }
            return returnValue
        }
        set {
            set(newValue, forKey: Key2.keyForAutoBasalDurationInHours.rawValue)
        }
    }
    
    public var durationAddManualTempBasalsInHours: Int {
        get {
            let returnValue = integer(forKey: Key2.keyForDurationAddManualTempBasalsInHours.rawValue)
            // if 0 set to default value
            if returnValue == 0 {
                set(1, forKey: Key2.keyForDurationAddManualTempBasalsInHours.rawValue)
            }
            return returnValue
        }
        set {
            set(newValue, forKey: Key2.keyForDurationAddManualTempBasalsInHours.rawValue)
        }
    }
    
}
