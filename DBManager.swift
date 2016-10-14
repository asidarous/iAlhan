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
                   
                    //print ("Here is the season data \(season)")
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
    

} // EOF
