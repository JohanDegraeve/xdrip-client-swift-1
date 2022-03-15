//
//  UIImage.swift
//  xDripClientUI
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import Foundation
import SwiftUI


extension UIImage {
    convenience init?(named name: String) {
        self.init(named: name, in: FrameworkBundle.main, compatibleWith: nil)
    }
}
