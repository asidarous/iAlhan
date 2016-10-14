//
//  DBManager.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/13/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit



class DBManager: NSObject {
    
    // declare fields in Season table
    let field_Season_Season = "season"
    let field_Season_SeasonID = "season_id"
    let field_Season_SeasonImage = "season_image"
    
    // declare fields in Event table
    let field_Event_EventName = "event_name"
    let field_Event_EventID = "event_id"
    let field_Event_EventSeasonFK = "event_season_fk"
    

    static let shared: DBManager = DBManager()
    let databaseFileName = "AlhanSQL"
    var pathToDatabase: String!
    var database: FMDatabase!
    
    
    override init() {
        super.init()
        
        pathToDatabase = Bundle.main.path(forResource: databaseFileName, ofType: "sqlite")
        
    }
    
    func openDatabase() -> Bool {
        if database == nil {
            
            //print("***** Path to Db \(pathToDatabase)")
            
            if FileManager.default.fileExists(atPath: pathToDatabase) {
                //print("Horray found file")
                database = FMDatabase(path: pathToDatabase)
            } else
            {
                print ("Cen't find file \(pathToDatabase)")
            }
        }
        
        if database != nil {
            if database.open() {
                return true
            }
        }
        
        return false
    }
    
    func loadSeasons() -> [SeasonData]! {
        var seasons: [SeasonData]!
        
        if openDatabase() {
            let query = "select * from season asc"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                //print("Query result \(results)")
                while results.next() {
                    let season = SeasonData(title: results.string(forColumn: field_Season_Season),
                                          seasonImage: results.string(forColumn: field_Season_SeasonImage),
                                          seasonID: Int (results.int(forColumn: field_Season_SeasonID))
                                          )
                   
                    //print ("+++ Here is the season \(season)")
                    if seasons == nil {
                        seasons = [SeasonData]()
                    }
                    
                    seasons.append(season)
                }
                //print (seasons.count)
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
            
        }
        
        return seasons
    
    }
    
    func loadSeasonHymns(WithID ID: Int) -> [SeasonHymns]{
        var seasonHymns: [SeasonHymns]!
        
        if openDatabase() {
            // this query will return all hymns for that season
            let query = "select * from hymn where hymn_event_id_fk in (select event_id from event where event_season_fk=?)"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: [ID])
                //print("Query result \(results)")
                while results.next() {
                    let hymn = SeasonHymns(hymnName: results.string(forColumn: "hymn_name")
                        
                    )
                    print ("$$$ Hymn \(hymn)")
                    if seasonHymns == nil {
                        seasonHymns = [SeasonHymns]()
                    }
                    
                    seasonHymns.append(hymn)
                }
                print (seasonHymns.count)
                print (seasonHymns)
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
            
        }
        
        return seasonHymns
        
    }

} // EOF
