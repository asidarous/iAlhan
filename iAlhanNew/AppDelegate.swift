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
        preserveLegacyDatabaseIfNeeded(at: destinationPath)
        
        // The writable hymns database lives in Documents. Installing a new app
        // build does not clear that directory, so explicitly promote a newer bundled DB.
        let destinationPathHymns = doumentDirectoryPath.appendingPathComponent("AlhanSQL3.sqlite")
        installBundledHymnDatabaseIfNeeded(at: destinationPathHymns)
        preserveLegacyDatabaseIfNeeded(at: destinationPathHymns)

    
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

    private func installBundledHymnDatabaseIfNeeded(at destinationPath: String) {
        guard let sourcePath = Bundle.main.path(forResource: "AlhanSQL3", ofType: "sqlite") else {
            print("Bundled AlhanSQL3.sqlite was not found")
            return
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: destinationPath) else {
            do {
                try fileManager.copyItem(atPath: sourcePath, toPath: destinationPath)
                print("Installed bundled AlhanSQL3.sqlite")
            } catch {
                print("Unable to install bundled hymn database: \(error.localizedDescription)")
            }
            return
        }

        guard let bundledVersion = databaseVersion(at: sourcePath),
              let installedVersion = databaseVersion(at: destinationPath),
              bundledVersion > installedVersion else {
            return
        }

        let backupPath = destinationPath + ".pre-update-\(installedVersion).backup"
        let temporaryPath = destinationPath + ".bundled-update"
        do {
            if !fileManager.fileExists(atPath: backupPath) {
                try fileManager.copyItem(atPath: destinationPath, toPath: backupPath)
            }
            if fileManager.fileExists(atPath: temporaryPath) {
                try fileManager.removeItem(atPath: temporaryPath)
            }
            try fileManager.copyItem(atPath: sourcePath, toPath: temporaryPath)
            _ = try fileManager.replaceItemAt(
                URL(fileURLWithPath: destinationPath),
                withItemAt: URL(fileURLWithPath: temporaryPath)
            )
            print("Updated AlhanSQL3.sqlite from \(installedVersion) to \(bundledVersion)")
        } catch {
            print("Unable to update bundled hymn database: \(error.localizedDescription)")
        }
    }

    private func databaseVersion(at path: String) -> Double? {
        let versionDatabase = FMDatabase(path: path)
        guard versionDatabase.open() else { return nil }
        defer { versionDatabase.close() }

        do {
            let results = try versionDatabase.executeQuery(
                "select version from version limit 1",
                values: nil
            )
            defer { results.close() }
            return results.next() ? results.double(forColumn: "version") : nil
        } catch {
            print("Unable to read hymn database version: \(error.localizedDescription)")
            return nil
        }
    }

    private func preserveLegacyDatabaseIfNeeded(at databasePath: String) {
        let backupPath = databasePath + ".legacy-backup"
        guard FileManager.default.fileExists(atPath: databasePath),
              !FileManager.default.fileExists(atPath: backupPath) else { return }
        do {
            try FileManager.default.copyItem(atPath: databasePath, toPath: backupPath)
        } catch {
            print("Unable to preserve legacy hymn database: \(error.localizedDescription)")
        }
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


