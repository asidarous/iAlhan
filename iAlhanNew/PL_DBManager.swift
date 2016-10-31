//
//  DBManager.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/13/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit



class PL_DBManager: NSObject {
    
    static let shared: PL_DBManager = PL_DBManager()
    var database: FMDatabase!
    
    var pl_databaseFileName = "AlhanPL"
    var pl_pathToDatabase: String!
    var error: NSError?
    
    let doumentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString

    
    override init() {
        super.init()
        
        pl_pathToDatabase = doumentDirectoryPath.appendingPathComponent("LocalAlhanPL.sqlite")
        
        
    }
    
    
        
    // Open DB Funtion
    func pl_openDatabase() -> Bool {
        if database == nil {
            
            print("***** Path to Db \(pl_pathToDatabase)")
            
            if FileManager.default.fileExists(atPath: pl_pathToDatabase) {
                print("Horray found file")
                database = FMDatabase(path: pl_pathToDatabase)
            } else
            {
                print ("Cen't find file \(pl_pathToDatabase)")
            }
        }
        
        if database != nil {
            if database.open() {
                return true
            }
        }
        
        return false
    }
    
    
 
    // MARK: Playlist calls
    
    func getPL() -> [String]!{
        var playLists: [String] = []
        
        if pl_openDatabase() {
            let query = "SELECT ListName FROM Playlists"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                //print("Query result \(results)")
                while results.next() {
                    //print("!!!!!!!!!!!!")
                    //print(results.string(forColumn: "ListName"))
                    playLists.append(results.string(forColumn: "ListName"))
                    
                }
                //print (seasons.count)
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
            
        }
        return playLists
    }
    
    func getPLHymns(){
    }
    
    func createPL(playlist: String){
        
        if pl_openDatabase() {
            let findQuery = "Select listname from playlists where listname = \"\(playlist)\" "
            let query = "INSERT INTO Playlists (\"ListName\") VALUES (\"\(playlist)\")"
            
            do {
                //print(database)
                
                // Make sure that there is no playlist by the same name
                let results = try database.executeQuery(findQuery, values: nil)
                if (results.next()) {
                    
                    let alert = UIAlertController(title: "Playlist name is already used", message: "Please select a different name", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    
                    let alertWindow = UIWindow(frame: UIScreen.main.bounds)
                    alertWindow.rootViewController = UIViewController()
                    alertWindow.windowLevel = UIWindowLevelAlert + 1;
                    alertWindow.makeKeyAndVisible()
                    alertWindow.rootViewController?.present(alert, animated: true, completion: nil)

                }else {
                    if ( database.executeUpdate(query, withArgumentsIn: nil) ) != true {
                        throw error!}
                }
                //print (seasons.count)
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
    }
    
    func addHymnsToPL(playlist: Int, hymnLists: [String:Int]){
            var values: String! = ""
    
            var i = hymnLists.makeIterator()
            while let hymn = i.next() {
                if values.isEmpty
                {
                  values = "(\(playlist), \(hymn.key.description), \(hymn.value.description))"
                  print("First value: \(values!)")
                    
                }else
                {
                    values = "\(values!),(\(playlist), \(hymn.key.description), \(hymn.value.description))"
                    
                }
            }
    
            print ("VAlues: \(values!)")
        
//            if pl_openDatabase() {
//                let query = "INSERT INTO ListDetail (\"list_id_fk\",\"HymnName\",\"HymnID\") VALUES (\(values))"
//    
//                do {
//                    //print(database)
//                    //let results =
//                        try database.executeQuery(query, values: nil)
//                    //print("Query result \(results)")
//    
//                    //print (seasons.count)
//                }
//                catch {
//                    print(error.localizedDescription)
//                }
//    
//                database.close()
//    
//            }
        }
    
    func removeHymnsFromPL(){
    }
    
    func deletePL(playlist: String){
        if pl_openDatabase() {
            let query = "DELETE FROM Playlists where LISTNAME = \"\(playlist)\""
            // TODO: delete all hymns pertaining to the deleted playlist
            print(query)
            do {
                if ( database.executeUpdate(query, withArgumentsIn: nil) ) != true {
                    throw error!}
                
                print ("Deleted!!!")
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }

        
    }
    
} // EOF
