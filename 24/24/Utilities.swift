//
//  Utilities.swift
//  24
//
//  Created by Belinda Zeng on 10/28/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import Foundation

func parseCSV(_ contentsOfURL: URL, encoding: String.Encoding, error: NSErrorPointer) -> [Problem]? {
    // Load the CSV file and parse it
    let delimiter: String = ","
    
    // Read CSV into array!
    var content = ""
    do {
        content = try NSString(contentsOf: contentsOfURL, encoding: encoding.rawValue) as String
    }
    catch{
        let nserror = error as NSError
        NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
        return nil
    }
    
    var problemData = [Problem]()
    // Ignore the first row as it contains header info
    let lines = (content.components(separatedBy: CharacterSet.newlines)).dropFirst()
    
    for line in lines {
        var values:[String] = []
        if line != "" {
            // For a line with double quotes
            // we use NSScanner to perform the parsing
            if line.range(of: "\"") != nil {
                var textToScan:String = line
                var value:NSString?
                var textScanner:Scanner = Scanner(string: textToScan)
                while textScanner.string != "" {
                    
                    if (textScanner.string as NSString).substring(to: 1) == "\"" {
                        textScanner.scanLocation += 1
                        textScanner.scanUpTo("\"", into: &value)
                        textScanner.scanLocation += 1
                    } else {
                        textScanner.scanUpTo(delimiter, into: &value)
                    }
                    
                    // Store the value into the values array
                    values.append(value as! String)
                    
                    // Retrieve the unscanned remainder of the string
                    if textScanner.scanLocation < textScanner.string.characters.count {
                        textToScan = (textScanner.string as NSString).substring(from: textScanner.scanLocation + 1)
                    } else {
                        textToScan = ""
                    }
                    textScanner = Scanner(string: textToScan)
                }
                
                // For a line without double quotes, we can simply separate the string
                // by using the delimiter (e.g. comma)
            } else  {
                values = line.components(separatedBy: delimiter)
            }
            
            // Put the values into the tuple and add it to the items array.
            guard let id = Int(values[0]) else { continue }
            guard let val1 = Int(values[1]) else { continue }
            guard let val2 = Int(values[2]) else { continue }
            guard let val3 = Int(values[3]) else { continue }
            guard let val4 = Int(values[4]) else { continue }
            guard let difficulty = Double(values[5]) else  {continue}
            
            problemData.append(Problem(id: id, values: [val1, val2, val3, val4], difficulty: difficulty))
        }
    }
    return problemData
}

func hasAppLaunchedBefore()->Bool{
    let defaults = UserDefaults.standard
    
    if let appVersion = defaults.string(forKey: "appVersion"){
        print("Running App Version : \(appVersion)")
        return true
    }
    else {
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject?
        let appVersion = nsObject as! String
        
        defaults.set(appVersion, forKey: "appVersion")
        return false
    }
}
