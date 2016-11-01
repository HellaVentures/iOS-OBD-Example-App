//
//  AppDelegate.swift
//  SwiftyOBD
//
//  Created by Daniel Montano on 06.10.16.
//  Copyright © 2016 Hella Ventures Berlin. All rights reserved.
//

import UIKit
import XCGLogger



//Singleton instance of the obdStreamManager
let obdStreamManager = OBDStreamManager.sharedInstance

//Singleton instance of the Hella Ventures OBD API
let apiManager = OBDAPIManager.sharedInstance



// XCGLOGGER
// Create a logger object with no destinations
let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
// Create a destination for the system console log (via NSLog)
let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        
        // SETUP the API Manager
        apiManager.client_id = "<<YOUR CLIENT ID>>" // TODO
        apiManager.client_secret = "<<YOUR CLIENT SECRET>>" // TODO
        
        
        
        
        //Customize the Navigation Bar
        let navigationBarAppereance = UINavigationBar.appearance()
        navigationBarAppereance.isTranslucent = false
        navigationBarAppereance.tintColor = UIColor.white
        navigationBarAppereance.barTintColor = UIColor(red: 18/255.0, green: 117.0/255.0, blue: 229.0/255.0, alpha: 1.0)
        navigationBarAppereance.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        
        // XCGLOGGER SETUP (from: https://github.com/DaveWoodCom/XCGLogger)
        // Optionally set some configuration options
        systemDestination.outputLevel = .debug
        systemDestination.showLogIdentifier = false
        systemDestination.showFunctionName = true
        systemDestination.showThreadName = false
        systemDestination.showLevel = true
        systemDestination.showFileName = true
        systemDestination.showLineNumber = true
        systemDestination.showDate = true
        // Add the destination to the logger
        log.add(destination: systemDestination)
        // Add basic app info, version info etc, to the start of the logs
        log.logAppDetails()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

