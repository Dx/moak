//
//  AppDelegate.swift
//  moak
//
//  Created by Dx on 08/08/16.
//  Copyright © 2016 Dx. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import GooglePlaces
import GoogleMaps
import Firebase
import FirebaseDatabase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var shortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		self.window?.tintColor = UIColor(red: 0.6171, green: 0.2617, blue: 0.2617, alpha: 1.0)
	GMSServices.provideAPIKey("AIzaSyDreT7fCLOxKN8rEkgK3yTDuho4TAkS_98")
	GMSPlacesClient.provideAPIKey("AIzaSyDreT7fCLOxKN8rEkgK3yTDuho4TAkS_98")
        GMSPlacesClient.openSourceLicenseInfo()
        
        FirebaseApp.configure()
        
        Database.database().isPersistenceEnabled = true
        
        var performShortcutDelegate = true
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            print("Application launched via shortcut")
            self.shortcutItem = shortcutItem
            
            performShortcutDelegate = false
        }
        
        if performShortcutDelegate {
        
            return ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        } else {
        	return false
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        print("ShortcutItem: \(shortcutItem.type)")
        completionHandler( handleShortcut(shortcutItem: shortcutItem) )
    }
    
    func handleShortcut( shortcutItem:UIApplicationShortcutItem ) -> Bool {
        print("Handling shortcut")
        
        var succeeded = false
        
        if( shortcutItem.type == "appshortcut.addproduct" ) {
            
            // Add your code here
            print("- Handling \(shortcutItem.type)")
            
            succeeded = true
            
        }
        
        return succeeded
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
        print("Application did become active")
        
        guard let shortcut = shortcutItem else { return }
        
        print("- Shortcut property has been set")
        
        _ = handleShortcut(shortcutItem: shortcut)
        
        self.shortcutItem = nil
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func createLevelsInFirebase() {
        let firebase = FirebaseClient()
        firebase.createLevels()
    }
}

