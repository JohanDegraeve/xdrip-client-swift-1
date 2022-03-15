//
//  xDripClientPlugin.swift
//  xDripClientPlugin
//
//  Created by Julian Groen on 14/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import Foundation
import LoopKitUI
import xDripClient
import xDripClientUI
import os.log


class xDripClientPlugin: NSObject, CGMManagerUIPlugin {
    
    private let log = OSLog(category: "xDripClientPlugin")
    
    public var cgmManagerType: CGMManagerUI.Type? {
        return xDripCGMManager.self
    }
    
    override init() {
        super.init()
        log.default("Instantiated xDripClient plugin.")
    }
}
