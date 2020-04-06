//
//  AppDelegate.swift
//  TestApp
//
//  Created by Julian Groen on 06/04/2020.
//  Copyright © 2020 Mark Wilson. All rights reserved.
//

import UIKit
import xDripClient
import xDripClientUI
import LoopKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let nav = xDripClientManager().settingsViewController(for: HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter()))
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }

    
}

