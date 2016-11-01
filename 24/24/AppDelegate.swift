//
//  AppDelegate.swift
//  24
//
//  Created by Luis Perez on 10/5/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import CoreData
import Mixpanel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // For 3D Touch
    enum ShortcutIdentifier: String {
        case ShareApp
        
        init?(fullIdentifier: String) {
            guard let shortIdentifier = fullIdentifier.components(separatedBy: ".").last else {
                return nil
            }
            print(shortIdentifier)
            self.init(rawValue: shortIdentifier)
        }
        
        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    func handleShortcut( _ shortcutItem:UIApplicationShortcutItem ) -> Bool {
        guard let _ = ShortcutIdentifier(fullIdentifier: shortcutItem.type) else {
            return false
        }
        
        let message = "Just found this great app -- check it out! "
        // activitiy view controller stuff
        if let view = self.window?.rootViewController
        {
            shareApp(view: view, message: message)
        }
        return true
    }
    
    var window: UIWindow?
    
    let defaults = UserDefaults.standard
    
    // for shortcuts
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {

        completionHandler( handleShortcut(shortcutItem) )
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if !hasAppLaunchedBefore() {
            preloadData()
        }
        // track with mixpanel
        Mixpanel.initialize(token: "426c2e3c58bccfab6acd351efa99c3b6")
        print(Mixpanel.mainInstance())
        // Disable sleep
        UIApplication.shared.isIdleTimerDisabled = true
        return true
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // Functions to clear data
    open func resetApplication() {
        let defaultsToReset: [String] = ["level", "puzzles", "score"]
        for key in defaultsToReset {
            defaults.removeObject(forKey: key)
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Problem")
        var results: [AnyObject]?
        do {
            results =
                try managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        let problems = results as? [NSManagedObject] ?? []
        for problem in problems {
          problem.setValue(false, forKey: "completed")
        }
    }
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "AppData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("24.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "24.error", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            // abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    open func saveContext () {
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
    
    private func preloadData () {
        // Retrieve data from the source file
        if let contentsOfFile = Bundle.main.url(forResource: "problems", withExtension: "csv") {
            
            var error:NSError?
            if let items = parseCSV(contentsOfFile, encoding: String.Encoding.utf8, error: &error) {
                // Preload the problem data!
                for item in items {
                    let entity = NSEntityDescription.entity(forEntityName: "Problem", in: managedObjectContext)
                    let problem = NSManagedObject(entity: entity!, insertInto: managedObjectContext)
                    
                    problem.setValue(item.id, forKey: "id")
                    problem.setValue(item.numbers, forKey: "numbers")
                    problem.setValue(item.difficulty, forKey: "difficulty")
                    problem.setValue(false, forKey: "completed")
                    
                    self.saveContext()
                }
            }
        }
    }
}

