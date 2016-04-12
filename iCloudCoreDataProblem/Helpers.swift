//
//  Helpers.swift
//  iCloudCoreDataProblem
//
//  Created by Maris Veide on 12.04.2016.
//  Copyright © 2016 ITissible. All rights reserved.
//

import Foundation

/// Prints message to stdout with additional info about the place it was called from.
func printDebug(message: AnyObject? = nil,
                         file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String
{
    let classString = file.componentsSeparatedByString("/").last!.componentsSeparatedByString(".").first!
    
    var msg:String! = ""
    
    if message != nil
    {
        msg = "\(message!)"
    }
    
    let line = "@ \(NSDate()): \(classString): \(function):\(line): \(msg)"
    
    print(line)
    
    return line
}
