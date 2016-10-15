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
    
    
    // Open DB Funtion
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
    
    // Load Seasons
    func loadSeasons() -> [SeasonData]! {
        var seasons: [SeasonData]!
        
        if openDatabase() {
            let query = "select * from season"
            
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
  
    
    // Load Season Events and Hymns in a dictionary

    func loadSeasonHymns(WithID ID: Int) -> [Any]{
        var seasonHymns = [Any]()
        
        if openDatabase() {
            // this query will return all events for that season
            let query = "select * from event where event_season_fk=? order by event_id asc"
            
            //print("Here is the event_season_fk \(ID)")
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: [ID])
                //print("Query result \(results)")
               
                while results.next() {
                    let event = results.string(forColumn: "event_name")
                    let eventID = Int (results.int(forColumn: "event_id"))
                    
                    let eventHymns = loadHymnsForEvent(WithID: eventID)
                    
                    // print ("**** returned Event Hymns \(eventHymns.description)")
                    
                    let seasonSection = SeasonHymns(seasonSections: [(event?.description)!: eventHymns])
                    
                    
                   // print ("$$$ seasonSection \(seasonSection.seasonSections)")

//                    if seasonHymns == nil {
//                        seasonHymns = [String: [String]]()
//                    }
                   
                    seasonHymns.append(seasonSection.seasonSections)
                    
                }
                // print (seasonHymns.count)
                 //print ("+++ From outside the while loop : \(seasonHymns)")
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
            
        }
        
        return seasonHymns
        
    }
    
    
    func loadHymnsForEvent(WithID ID: Int) -> [String]{
        var eventHymns: [String]!
        var dbOpen: Bool?
        
        
        // Due to the fact that we're making this call inside another DB connection
        // let's check if a connection exists, otherwise initiate it
        
        if !database.goodConnection() {
            
            if  openDatabase() {
            dbOpen = true
            }
        }
        else
        {
            // this query will return all hymns for that event
            let query = "select * from hymn where hymn_event_id_fk=? order by hymn_id asc"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: [ID])
                //print("Query result \(results)")
                while results.next() {
                    
                    let hymn = EventHymns(hymnName: results.string(forColumn: "hymn_name")
                        
                    )
                    //print ("$-$-$ Hymn \(hymn.hymnName)")
                    if eventHymns == nil {
                        eventHymns = [String]()
                    }
                    
                    eventHymns.append(hymn.hymnName)
                }
                // print (seasonHymns.count)
                // print ("///// Event hymns: \(eventHymns.description)")
                results.close()
            }
            catch {
                print(error.localizedDescription)
            }
            
            if dbOpen == true {
            database.close()
            }
            
        }
        
        return eventHymns
        
    }


} // EOF
