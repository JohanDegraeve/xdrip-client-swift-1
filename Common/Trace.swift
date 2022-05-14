import Foundation
import os

/// log only used for debuglogging
fileprivate var log:OSLog = {
    let log:OSLog = OSLog(subsystem: ConstantsxDripClient.osLogSubSystemName, category: ConstantsxDripClient.debuglogging)
    return log
}()

/// dateformatter for nslog
fileprivate let dateFormatNSLog: DateFormatter = {
    
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = "y-MM-dd HH:mm:ss.SSSS"
    
    return dateFormatter
    
}()

/// used during development
func debuglogging(_ logtext:String) {
    os_log("%{public}@", log: log, type: .debug, logtext)
}

/// finds the path to where loop can save files
fileprivate func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

/// filename  for tracing. (UI would not be be developed to send the file via e-mail
fileprivate var traceFileName:URL?


/// function to be used for logging, takes same parameters as os_log but in a next phase also NSLog can be added, or writing to disk to send later via e-mail ..
/// - message : the text, same format as in os_log with %{private} and %{public} to either keep variables private or public , for NSLog, only 3 String formatters are suppored "@" for String, "d" for Int, "f" for double.
/// - category is the same as used for creating the log (see class ConstantsLog), it's repeated here to use in NSLog
/// - args : optional list of parameters that will be used. MAXIMUM 10 !
///
/// Example
func trace(_ message: StaticString, category: String, _ args: CVarArg...) {
    
    // initialize traceFileName if needed
    if traceFileName ==  nil {
        traceFileName = getDocumentsDirectory().appendingPathComponent(ConstantsxDripClient.traceFileName + ".0.log")
    }
    guard let traceFileName = traceFileName else {return}

    var argumentsCounter: Int = 0
    
    var actualMessage = message.description
    
    // try to find the publicMark as long as argumentsCounter is less than the number of arguments
    while argumentsCounter < args.count {
        
        // mark to replace
        let publicMark = "%{public}"
        
        // get array of indexes of location of publicMark
        let indexesOfPublicMark = actualMessage.indexes(of: "%{public}")
        
        if indexesOfPublicMark.count > 0 {
            
            // range starts from first character until just before the publicMark
            let startOfMessageRange = actualMessage.startIndex..<indexesOfPublicMark[0]
            // text as String, until just before the publicMark
            let startOfMessage = String(actualMessage[startOfMessageRange])
            
            // range starts from just after the publicMark till the end
            var endOfMessageRange = actualMessage.index(indexesOfPublicMark[0], offsetBy: publicMark.count)..<actualMessage.endIndex
            // text as String, from just after the publicMark till the end
            var endOfMessage = String(actualMessage[endOfMessageRange])
            
            // no start looking for String Format Specifiers
            // possible formatting see https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html#//apple_ref/doc/uid/TP40004265
            // not doing them all
            
            if endOfMessage.starts(with: "@") {
                let indexOfAt = endOfMessage.indexes(of: "@")
                endOfMessageRange = endOfMessage.index(after: indexOfAt[0])..<endOfMessage.endIndex
                endOfMessage = String(endOfMessage[endOfMessageRange])
                if let argValue = args[argumentsCounter] as? String {
                    endOfMessage = argValue + endOfMessage
                }
            } else if endOfMessage.starts(with: "d") || endOfMessage.starts(with: "D") {
                let indexOfAt = endOfMessage.indexes(of: "d", options: [NSString.CompareOptions.caseInsensitive])
                endOfMessageRange = endOfMessage.index(after: indexOfAt[0])..<endOfMessage.endIndex
                endOfMessage = String(endOfMessage[endOfMessageRange])
                if let argValue = args[argumentsCounter] as? Int {
                    endOfMessage = argValue.description + endOfMessage
                }
            } else if endOfMessage.starts(with: "f") || endOfMessage.starts(with: "F") {
                let indexOfAt = endOfMessage.indexes(of: "f", options: [NSString.CompareOptions.caseInsensitive])
                endOfMessageRange = endOfMessage.index(after: indexOfAt[0])..<endOfMessage.endIndex
                endOfMessage = String(endOfMessage[endOfMessageRange])
                if let argValue = args[argumentsCounter] as? Double {
                    endOfMessage = argValue.description + endOfMessage
                }
            }
            
            actualMessage = startOfMessage + endOfMessage
            
        } else {
            // there's no more occurrences of the publicMark, no need to continue
            break
        }
        
        argumentsCounter += 1
        
    }
    
    // create timeStamp to use in NSLog and tracefile
    let timeStamp = dateFormatNSLog.string(from: Date())
    
    NSLog("%@", ConstantsxDripClient.tracePrefix + " " + timeStamp + " " + category + " " + actualMessage)
    
    // write trace to file
    do {
        
        let textToWrite = timeStamp + " " + category + " " + actualMessage + "\n"
        
        if let fileHandle = FileHandle(forWritingAtPath: traceFileName.path) {
            
            // file already exists, go to end of file and append text
            fileHandle.seekToEndOfFile()
            fileHandle.write(textToWrite.data(using: .utf8)!)
            
        } else {
            
            // file doesn't exist yet
            try textToWrite.write(to: traceFileName, atomically: true, encoding: String.Encoding.utf8)
            
        }
        
    } catch {
        
        NSLog("%@", ConstantsxDripClient.tracePrefix + " " + dateFormatNSLog.string(from: Date()) + " write trace to file failed")
        
    }

    // check if tracefile has reached limit size and if yes rotate the files
    if traceFileName.fileSize > 3 * 1024 * 1024 {
        
        rotateTraceFiles()
        
    }
    
}

fileprivate func rotateTraceFiles() {
    
    // assign fileManager
    let fileManager = FileManager.default
    
    // first check if last trace file exists
    let lastFile = getDocumentsDirectory().appendingPathComponent(ConstantsxDripClient.traceFileName + ".0.log")
    
    if FileHandle(forWritingAtPath: lastFile.path) != nil {
        
        do {
            try fileManager.removeItem(at: lastFile)
        } catch {
            debuglogging("failed to delete file " + lastFile.absoluteString)
        }
        
    }
    
    // now rename trace files if they exist,
    for indexFrom0ToMax in 0...1 {
        
        let index = 1 - indexFrom0ToMax
        
        let file = getDocumentsDirectory().appendingPathComponent(ConstantsxDripClient.traceFileName + "." + index.description + ".log")
        let newFile = getDocumentsDirectory().appendingPathComponent(ConstantsxDripClient.traceFileName + "." + (index + 1).description + ".log")
        
        if FileHandle(forWritingAtPath: file.path) != nil {
            
            do {
                try fileManager.moveItem(at: file, to: newFile)
            } catch {
                debuglogging("failed to rename file " + lastFile.absoluteString)
            }
            
        }
    }
    
    // now set tracefilename to nil, it will be reassigned to correct name, ie the one with index 0, at next usage
    traceFileName = nil
    
}

public class Trace {
    
    public init() {
        
    }
    
    /// returns tuple, first type is an array of Data, each element is a tracefile converted to Data, second type is String, each element is the name of the tracefile
    public static func getTraceFilesInData() -> ([Data], [String]) {
        
        var traceFilesInData = [Data]()
        var traceFileNames = [String]()
        
        for index in 0..<3 {
            
            let filename = ConstantsxDripClient.traceFileName + "." + index.description + ".log"
            
            let file = getDocumentsDirectory().appendingPathComponent(filename)
            
            if FileHandle(forWritingAtPath: file.path) != nil {
                
                do {
                    // create traceFile info as data
                    let fileData = try Data(contentsOf: file)
                    traceFilesInData.append(fileData)
                    traceFileNames.append(filename)
                } catch {
                    debuglogging("failed to create data from  " + filename)
                }
                
            }
        }
        
        return (traceFilesInData, traceFileNames)
        
    }
    
    /// to call Trace function from other modules. Code in the xDripClient module can directly call trace without using the Class Trace
    public func callTrace(_ message: StaticString, category: String, _ args: CVarArg...) {
        trace(message, category: category, args)
    }
    
}
