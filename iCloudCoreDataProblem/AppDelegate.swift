//
//  AppDelegate.swift
//  iCloudCoreDataProblem
//
//  Created by Maris Veide on 12.04.2016.
//  Copyright © 2016 ITissible. All rights reserved.
//

import UIKit
import CoreData

var dataStore: DataStore!

var testItem: Item?
var items: [Item]?


// Reproduction of problem described here:
// http://stackoverflow.com/questions/36567966/managedobjectcontext-for-nsmanagedobject-becomes-nil-after-restoring-app-from-in
//
// To see the result:
// 0. While logged out of iCloud on Simulator
// 1. Run App
// 2. Read Debug Console
// 3. Press Home button
// 4. Press App icon to restore the app
// 5. See in Debug Console that "- Context: nil"
// 6. Comment the following line in DataStore.swift: self.stack.updateContextWithUbiquitousContentUpdates = true
// 7. Now all Contexts after app restore will be in tact - will not be nil. But App will not get the iCloud updates.



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?

    
    func printItems()
    {
        print("testItem: \(testItem)\n")
        
        for item in items ?? []
        {
            print("\t* Item: \(item)")
            print("\t\t- Context: \(item.managedObjectContext)")
        }
    }
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        dataStore = DataStore()
        
        testItem = dataStore.createItem("aa")
        dataStore.save()
        
        items = dataStore.itemQuery()
        testItem = items?.last
        
        printItems()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication)
    {
        print("applicationWillResignActive")
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication)
    {
        print("applicationDidEnterBackground")
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication)
    {
        print("applicationWillEnterForeground")

        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication)
    {
        print("==========================================")
        print("applicationDidBecomeActive")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        printItems()
        
        
    }

    func applicationWillTerminate(application: UIApplication)
    {
        print("applicationWillTerminate")
        
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
}

