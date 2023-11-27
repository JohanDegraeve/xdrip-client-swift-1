//
//  xDripCGMManager+UI.swift
//  xDripClientUI
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import SwiftUI
import HealthKit
import LoopKit
import LoopKitUI
import xDripClient


extension xDripCGMManager: CGMManagerUI {
    
    public static var onboardingImage: UIImage? {
        return UIImage(named: "xDrip4iOS")
    }

    public static func setupViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool, prefersToSkipUserInteraction: Bool) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        return .userInteractionRequired(UICoordinator(cgmManager: xDripCGMManager(), displayGlucosePreference: displayGlucosePreference, colorPalette: colorPalette))
    }
    
    public var smallImage: UIImage? {
        return UIImage(named: "xDrip4iOS")
    }
    
    public func settingsViewController(bluetoothProvider: BluetoothProvider, displayGlucosePreference: DisplayGlucosePreference, colorPalette: LoopUIColorPalette, allowDebugFeatures: Bool) -> CGMManagerViewController {
        return UICoordinator(cgmManager: self, displayGlucosePreference: displayGlucosePreference, colorPalette: colorPalette)
    }
    
    public var cgmStatusHighlight: DeviceStatusHighlight? {
        return nil
    }
    
    public var cgmLifecycleProgress: DeviceLifecycleProgress? {
        return nil
    }
    
    public var cgmStatusBadge: DeviceStatusBadge? {
        return nil
    }
}
