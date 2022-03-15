//
//  xDripReading.swift
//  xDripClient
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import Foundation
import LoopKit
import LoopKitUI
import HealthKit

public struct xDripReading: GlucoseValue, GlucoseDisplayable {
    
    public var trendType: GlucoseTrend?
    
    public var trendRate: HKQuantity?
    
    public var isLocal: Bool = false
    
    public var glucoseRangeCategory: GlucoseRangeCategory?
    
    public var quantity: HKQuantity
    
    public var startDate: Date
    
    public var isStateValid: Bool {
        let glucoseValue = quantity.doubleValue(for: .milligramsPerDeciliter)
        return glucoseValue >= 39 && glucoseValue <= 500
    }
}
