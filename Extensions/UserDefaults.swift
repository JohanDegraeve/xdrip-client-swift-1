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
        
    }
    
    /// should the app automatically show the translated version of the online help if English (en) is not the selected app locale?
    var addManualTempBasals: Bool {

        get {
            return bool(forKey: Key2.keyForAddManualTempBasals.rawValue)
        }
        set {
            set(newValue, forKey: Key2.keyForAddManualTempBasals.rawValue)
        }
    }

}
