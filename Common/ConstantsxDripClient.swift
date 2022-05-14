//
//  Constants.swift
//  xDripClient
//
//  Created by Johan Degraeve on 14/05/2022.
//  Copyright © 2022 Randall Knutson. All rights reserved.
//

import Foundation

enum ConstantsxDripClient {

    /// for use in NSLog
    static let tracePrefix = "loop-NSLog"

    /// email address to which to send trace file
    static let traceFileDestinationAddress = "xdrip@proximus.be"

    /// - will be used as filename to store traces on disk, and attachment file name when sending trace via e-mail
    /// - filename will be extended with digit, eg looptrace.0.log, or looptrace.1.log - the latest trace file is always looptrace.0.log
    static let traceFileName = "looptrace"
    
    /// maximum size of one trace file, in MB. If size is larger, files will rotate, ie all trace files will be renamed, from looptrace.2.log to looptrace.3.log, from looptrace.1.log to looptrace.2.log, from looptrace.0.log to looptrace.1.log,
    static let maximumFileSizeInMB: UInt64 = 3
    
    /// maximum amount of trace files to hold. When rotating, and if value is 3, then tracefile looptrace.2.log will be deleted
    static let maximumAmountOfTraceFiles = 3
    
    /// used only in logging
    static let osLogSubSystemName = "xDripClientSwift"
    
    /// category used in debug logging
    static let debuglogging = "loopdebuglogging"

}

