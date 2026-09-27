//
//  DBManager.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/13/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit



@MainActor
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
            
            print("***** Path to Db \(String(describing: pl_pathToDatabase))")
            
            if FileManager.default.fileExists(atPath: pl_pathToDatabase) {
                print("Horray found file")
                database = FMDatabase(path: pl_pathToDatabase)
            } else
            {
                print ("Cen't find file \(String(describing: pl_pathToDatabase))")
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
                    playLists.append(results.string(forColumn: "ListName")!)
                    
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
            ensureSortOrderColumn()
            let query = "select HymnName, HymnID, HymnURL from listdetail where list_id_fk in (select id from playlists where listname = '\(playlist)') order by SortOrder, rowid"
            
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
    
    func createPL(playlist: String) -> Bool {
        guard pl_openDatabase() else { return false }

        let findQuery = "Select listname from playlists where listname = \"\(playlist)\" "
        let query = "INSERT INTO Playlists (\"ListName\") VALUES (\"\(playlist)\")"
        var wasCreated = false

        do {
            let results = try database.executeQuery(findQuery, values: nil)
            if !results.next() {
                wasCreated = database.executeUpdate(query, withArgumentsIn: [])
            }
        } catch {
            print(error.localizedDescription)
        }

        database.close()
        return wasCreated
    }
    
    func addHymnsToPL(playlist: Int, hymnLists: [PlayHymns]) -> [String] {
        guard !hymnLists.isEmpty, pl_openDatabase() else { return [] }
        ensureSortOrderColumn()

        let duplicateQuery = """
            SELECT 1
            FROM ListDetail
            WHERE list_id_fk = ? AND HymnID = ?
            LIMIT 1
            """
        let insertQuery = """
            INSERT INTO ListDetail ("list_id_fk", "HymnName", "HymnID", "HymnURL", "SortOrder")
            VALUES (
                ?, ?, ?, ?,
                COALESCE(
                    (SELECT MAX(SortOrder) + 1 FROM ListDetail WHERE list_id_fk = ?),
                    0
                )
            )
            """
        var duplicateHymnNames: [String] = []

        for hymn in hymnLists {
            guard let hymnName = hymn.HymnName,
                  let hymnID = hymn.HymnID,
                  let hymnURL = hymn.HymnURL else {
                continue
            }

            do {
                let results = try database.executeQuery(
                    duplicateQuery,
                    values: [playlist, hymnID]
                )
                let isDuplicate = results.next()
                results.close()

                if isDuplicate {
                    duplicateHymnNames.append(hymnName)
                    continue
                }
            } catch {
                print(error.localizedDescription)
                continue
            }

            let values: [Any] = [
                playlist,
                hymnName,
                hymnID,
                hymnURL,
                playlist
            ]

            if !database.executeUpdate(insertQuery, withArgumentsIn: values) {
                print(database.lastErrorMessage())
            }
        }

        database.close()
        return duplicateHymnNames
    }

    func reorderHymns(in playlist: Int, orderedHymnIDs: [Int]) {
        guard pl_openDatabase() else { return }
        ensureSortOrderColumn()

        let query = """
            UPDATE ListDetail
            SET SortOrder = ?
            WHERE list_id_fk = ? AND HymnID = ?
            """

        for (sortOrder, hymnID) in orderedHymnIDs.enumerated() {
            if !database.executeUpdate(
                query,
                withArgumentsIn: [sortOrder, playlist, hymnID]
            ) {
                print(database.lastErrorMessage())
            }
        }

        database.close()
    }

    private func ensureSortOrderColumn() {
        var hasSortOrder = false

        do {
            let columns = try database.executeQuery("PRAGMA table_info(ListDetail)", values: nil)
            while columns.next() {
                if columns.string(forColumn: "name") == "SortOrder" {
                    hasSortOrder = true
                    break
                }
            }
        } catch {
            print(error.localizedDescription)
            return
        }

        if !hasSortOrder {
            if database.executeUpdate(
                "ALTER TABLE ListDetail ADD COLUMN SortOrder INTEGER",
                withArgumentsIn: []
            ) {
                _ = database.executeUpdate(
                    "UPDATE ListDetail SET SortOrder = rowid WHERE SortOrder IS NULL",
                    withArgumentsIn: []
                )
            } else {
                print(database.lastErrorMessage())
            }
        }
    }
    
    func removeHymnsFromPL(hymnID: Int){
        
        if pl_openDatabase() {
            let query = "DELETE FROM Listdetail where HymnId = \(hymnID)"
            
            print(query)
            do {
                if ( database.executeUpdate(query, withArgumentsIn: []) ) != true {
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
                if ( database.executeUpdate(query, withArgumentsIn: []) ) != true {
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
