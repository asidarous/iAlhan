//
//  AppDelegate.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/6/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit
import AVFoundation
public var update: Bool = false


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let barbuttonFont = UIFont(name: "verdana", size: 12) ?? UIFont.systemFont(ofSize: 12)
        
        
        UIBarButtonItem.appearance().setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): barbuttonFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor):UIColor.clear]), for: UIControl.State.normal)
        
        
        
        
        
        let fileManger = FileManager.default
        let doumentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let destinationPath = doumentDirectoryPath.appendingPathComponent("LocalAlhanPL.sqlite")
        let sourcePath = Bundle.main.path(forResource: "AlhanPL", ofType: "sqlite")
        
        if FileManager.default.fileExists(atPath: destinationPath) {
            print("The file already exists at path")
            
            // if the file doesn't exist
        } else {
        
        
            do{
               try fileManger.copyItem(atPath: sourcePath!, toPath: destinationPath)
                print("Copied the file successfully to \(destinationPath)")
                }
            catch let error as NSError {
                NSLog("Unable to copy PlaylistDB to  directory \(error.debugDescription)")
            }

        }
        
        // For the hymns DB
        let destinationPathHymns = doumentDirectoryPath.appendingPathComponent("AlhanSQL3.sqlite")
        let sourcePathHymns = Bundle.main.path(forResource: "AlhanSQL3", ofType: "sqlite")
        
        if FileManager.default.fileExists(atPath: destinationPathHymns) {
            print("AlhanSQL3.sqlite already exists at path")
            
            // if the file doesn't exist
        } else {
            
            
            do{
                try fileManger.copyItem(atPath: sourcePathHymns!, toPath: destinationPathHymns)
                print("Copied AlhanSQL3 successfully to \(destinationPathHymns)")
            }
            catch let error as NSError {
                NSLog("Unable to copy PlaylistDB to  directory \(error.debugDescription)")
            }
            
        }

    
        if Reachability.isConnectedToNetwork(){
            update = CheckVersion()
        }
    
        
        
        // Register a UserDefaults Domain
        //UserDefaults.register("PlayListDomain")
        
        //navigationController?
         //print("~~~WIDTH -- \(UINavigationController().navigationItem.leftBarButtonItem!.width)")
        
        //setTitleTextAttributes([NSFontAttributeName: UIFont(name: "copt", size: 10)!], for: .normal)
        
        
        //UINavigationBar.appearance().titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Verdana", size: 10)!]
            //.sizeThatFits(CGSize(width: 30, height: 50))
            //.tintColor = UIColor.blue
        //    = [ NSFontAttributeName: UIFont(name: "Verdana", size: 10)!]
        
        //UINavigationController().navigationItem.leftBarButtonItem?.tintColor = UIColor.blue
        //UINavigationController().navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Verdana", size: 10)!], for:.normal)
        
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


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
