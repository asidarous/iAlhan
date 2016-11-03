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
    
    func getPLHymns(playlist: String) -> [PlaylistHymns]!{
        var hymnsLists: [PlaylistHymns]!
        
        if pl_openDatabase() {
            let query = "select HymnName, HymnID, HymnURL from listdetail where list_id_fk in (select id from playlists where listname = '\(playlist)')"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                //print("Query result \(results)")
                while results.next() {
                    let hymnsList = PlaylistHymns(HymnName: results.string(forColumn: "HymnName"), HymnID: Int (results.int(forColumn: "HymnID")), HymnURL: results.string(forColumn: "HymnURL") )
                    
                    //print ("+++ Here is the season \(season)")
                    if hymnsLists == nil {
                        hymnsLists = [PlaylistHymns]()
                    }
                    
                    hymnsLists.append(hymnsList)
                }
                //print (seasons.count)
            }
            catch {
                print(error.localizedDescription)
            }
            database.close()
            
        }
        return hymnsLists
        
        
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
    
    func addHymnsToPL(playlist: Int, hymnLists: [PlayHymns]){
            var values: String! = ""
    
            var i = hymnLists.makeIterator()
            while let hymn = i.next() {
                if values.isEmpty
                {
                  values = "(\(playlist), '\(hymn.HymnName!)', \(hymn.HymnID!), '\(hymn.HymnURL!)')"
                  print("First value: \(values!)")
                    
                }else
                {
                    values = "\(values!),(\(playlist), '\(hymn.HymnName!)', \(hymn.HymnID!), '\(hymn.HymnURL!)')"
                    
                }
            }
    
            print ("VAlues: \(values!)")
        
            if pl_openDatabase() {
                let query = "INSERT INTO ListDetail (\"list_id_fk\",\"HymnName\",\"HymnID\",\"HymnURL\") VALUES \(values!)"
                print("QUERY")
                print(query)
                do {
                    if ( database.executeUpdate(query, withArgumentsIn: nil) ) != true {
                        throw error!}
                    
                    print ("Updated!!!")
                }
                catch {
                    print(error.localizedDescription)
                }
    
                database.close()
    
            }
        }
    
    func removeHymnsFromPL(hymnID: Int){
        
        if pl_openDatabase() {
            let query = "DELETE FROM Listdetail where HymnId = \(hymnID)"
            
            print(query)
            do {
                if ( database.executeUpdate(query, withArgumentsIn: nil) ) != true {
                    throw error!}
                
                print ("Hymn Successfully Deleted!!!")
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
        }
        

        
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
    
    func getPLID (playlist: String) -> Int{
        var playlistID: Int!
        if pl_openDatabase() {
            let query = "SELECT ID FROM Playlists where LISTNAME = \"\(playlist)\""
            // TODO: delete all hymns pertaining to the deleted playlist
            print(query)
            //var playlistID: Int
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                if (results.next()) {
                print("Query result \(Int (results.int(forColumn: "ID")))")
                //while results.next() {
                playlistID = Int (results.int(forColumn: "ID"))
                }
                //}
                //print (seasons.count)
            }
            catch {
                print(error.localizedDescription)
            }

            
            database.close()
        }
        
        return playlistID
    }
    
} // EOF
