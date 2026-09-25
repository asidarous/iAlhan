//
//  AppDelegate.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/6/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit
import AVFoundation
@MainActor public var update: Bool = false


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let barbuttonFont = UIFont(name: "verdana", size: 12) ?? UIFont.systemFont(ofSize: 12)
        
        
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [.font: barbuttonFont, .foregroundColor: UIColor.clear],
            for: .normal
        )
        
        
        
        
        
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

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {

        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
    
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
    }

}


