//
//  AppDelegate.swift
//  24
//
//  Created by Luis Perez on 10/5/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import CoreData

typealias Problem = (id : Int, problem : [Int], difficulty: Double)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    //for force touch
    enum ShortcutIdentifier: String {
        case ShareApp
        
        init?(fullIdentifier: String) {
            guard let shortIdentifier = fullIdentifier.componentsSeparatedByString(".").last else {
                return nil
            }
            self.init(rawValue: shortIdentifier)
        }
    }
    
    var window: UIWindow?
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // for shortcuts
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController : UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("OptionsViewController") as UIViewController
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
    //        window!.rootViewController?.presentViewController(vc, animated: true, completion: nil)
        
        
        completionHandler( handleShortcut(shortcutItem) )
        
    }
    
    func handleShortcut( shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling shortcut")
        
        let shortcutType = shortcutItem.type
        print(shortcutType)
        guard let shortcutIdentifier = ShortcutIdentifier(fullIdentifier: shortcutType) else {
            return false
        }
        print(shortcutIdentifier)
        return true
    }
    
    // end for shortcut

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if !hasAppLaunchedBefore() {
            preloadData()
        }
        
        return true
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // Functions to clear data
    func resetApplication() {
        let defaultsToReset: [String] = ["level", "puzzles", "score"]
        for key in defaultsToReset {
            defaults.removeObjectForKey(key)
        }
        
        let fetchRequest = NSFetchRequest(entityName: "Problem")
        var results: [AnyObject]?
        do {
            results =
                try managedObjectContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        let problems = results as? [NSManagedObject] ?? []
        for problem in problems {
          problem.setValue(false, forKey: "completed")
        }
    }
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("AppData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("24.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "24.error", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            // abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    /*******
     * Helper functions for loading data
     *******/
    func preloadData () {
        // Retrieve data from the source file
        if let contentsOfFile = NSBundle.mainBundle().URLForResource("problems", withExtension: "csv") {
            
            var error:NSError?
            if let items = parseCSV(contentsOfFile, encoding: NSUTF8StringEncoding, error: &error) {
                // Preload the problem data!
                for item in items {
                    let entity = NSEntityDescription.entityForName("Problem", inManagedObjectContext: managedObjectContext)
                    let problem = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                    
                    problem.setValue(item.id, forKey: "id")
                    problem.setValue(item.problem, forKey: "numbers")
                    problem.setValue(item.difficulty, forKey: "difficulty")
                    problem.setValue(false, forKey: "completed")
                
                    self.saveContext()
                }
            }
        }
    }
    
    func parseCSV(contentsOfURL: NSURL, encoding: NSStringEncoding, error: NSErrorPointer) -> [Problem]? {
        // Load the CSV file and parse it
        let delimiter: String = ","
        var problemData: [Problem]?
        
        // Read CSV into array!
        var content = ""
        do {
            content = try NSString(contentsOfURL: contentsOfURL, encoding: encoding) as String
        }
        catch{
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            return nil
        }
        problemData = []
        
        // Ignore the first row as it contains header info
        let lines = (content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())).dropFirst()
        
        for line in lines {
            var values:[String] = []
            if line != "" {
                // For a line with double quotes
                // we use NSScanner to perform the parsing
                if line.rangeOfString("\"") != nil {
                    var textToScan:String = line
                    var value:NSString?
                    var textScanner:NSScanner = NSScanner(string: textToScan)
                    while textScanner.string != "" {
                        
                        if (textScanner.string as NSString).substringToIndex(1) == "\"" {
                            textScanner.scanLocation += 1
                            textScanner.scanUpToString("\"", intoString: &value)
                            textScanner.scanLocation += 1
                        } else {
                            textScanner.scanUpToString(delimiter, intoString: &value)
                        }
                        
                        // Store the value into the values array
                        values.append(value as! String)
                        
                        // Retrieve the unscanned remainder of the string
                        if textScanner.scanLocation < textScanner.string.characters.count {
                            textToScan = (textScanner.string as NSString).substringFromIndex(textScanner.scanLocation + 1)
                        } else {
                            textToScan = ""
                        }
                        textScanner = NSScanner(string: textToScan)
                    }
                    
                    // For a line without double quotes, we can simply separate the string
                    // by using the delimiter (e.g. comma)
                } else  {
                    values = line.componentsSeparatedByString(delimiter)
                }
                
                // Put the values into the tuple and add it to the items array
                let singleProblem: Problem = (id: Int(values[0]) ?? 0, problem: [Int(values[1]) ?? 1, Int(values[2]) ?? 0, Int(values[3]) ?? 0, Int(values[4]) ?? 0], difficulty: Double(values[5]) ?? 1.0)
                problemData?.append(singleProblem)
            }
        }
        return problemData
    }
    
    func hasAppLaunchedBefore()->Bool{
        let defaults = NSUserDefaults.standardUserDefaults()
        
        if let appVersion = defaults.stringForKey("appVersion"){
            print("Running App Version : \(appVersion)")
            return true
        }
        else {
            let nsObject: AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
            let appVersion = nsObject as! String

            defaults.setObject(appVersion, forKey: "appVersion")
            return false
        }
    }

}

