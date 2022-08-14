//
//  UserDefaults.swift
//  xDripClient
//
//  Created by Johan Degraeve on 13/08/2022.
//  Copyright © 2022 Randall Knutson. All rights reserved.
//

import Foundation

extension UserDefaults {
  
    /// using Key2 because Key already exists in xDripCGMManager
    public enum Key2: String {
    
        /// shoud manual temp basals be included in glucose effects  calculation, yes or no - default false
        case keyForAddManualTempBasals = "keyForAddManualTempBasals"
        
        /// should basal be adapted depending on current bg value
        case keyForUseVariableBasal = "keyForUseVariableBasal"
        
        /// in case keyForUseVariableBasal is true, this is the percentage to be used
        case keyForPercentageVariableBasal = "keyForPercentageVariableBasal"
        
    }
    
    /// shoud manual temp basals be included in glucose effects  calculation, yes or no - default false
    public var addManualTempBasals: Bool {

        get {
            return bool(forKey: Key2.keyForAddManualTempBasals.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyForAddManualTempBasals.rawValue)
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
    
    /// in case keyForUseVariableBasal is true, this is the percentage to be used - value between 0 and 100 - default 100
    var percentageVariableBasal: Int {
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
