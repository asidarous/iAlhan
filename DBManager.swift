//
//  DBManager.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/13/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit



@MainActor
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
    let databaseFileName = "AlhanSQL3"
    var pathToDatabase: String!
    var database: FMDatabase!
    var pl_database: FMDatabase!
    private var didCheckCopticMigration = false
    
    var pl_databaseFileName = "AlhanPL"
    var pl_pathToDatabase: String!
    
    let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    
    
    override init() {
        super.init()
        
        //pathToDatabase = Bundle.main.path(forResource: databaseFileName, ofType: "sqlite")
        pathToDatabase = documentDirectoryPath.appendingPathComponent("AlhanSQL3.sqlite")
        pl_pathToDatabase = documentDirectoryPath.appendingPathComponent("LocalAlhanPL.sqlite")


    }
    
    
    // Open DB Funtion
    func openDatabase() -> Bool {
        if database == nil {
            
            print(Bundle.main)
            print("***** Path to Db \(String(describing: pathToDatabase))")
            
            if FileManager.default.fileExists(atPath: pathToDatabase) {
                //print("Horray found file")
                database = FMDatabase(path: pathToDatabase)
            } else
            {
                print ("Cen't find file \(String(describing: pathToDatabase))")
            }
        }
        
        if database != nil {
            if database.open() {
                migrateLegacyCopticIfNeeded()
                return true
            }
        }
        
        return false
    }
    
    private func migrateLegacyCopticIfNeeded() {
        guard !didCheckCopticMigration else { return }
        didCheckCopticMigration = true

        let migrationIdentifier = "coptic_unicode_v5"
        let createMetadata = """
            create table if not exists app_migration (
                identifier text primary key
            )
            """
        guard database.executeUpdate(createMetadata, withArgumentsIn: []) else {
            print(database.lastErrorMessage())
            return
        }

        do {
            let marker = try database.executeQuery(
                "select identifier from app_migration where identifier=? limit 1",
                values: [migrationIdentifier]
            )
            let wasMigrated = marker.next()
            marker.close()
            guard !wasMigrated else { return }

            // Always migrate the database that is currently installed. A legacy
            // backup may belong to an older bundled version and must not overwrite newer data.
            let results = try database.executeQuery(
                "select hymn_id, hymn_name, hymn_coptic from hymn",
                values: nil
            )
            var updates = [(Int, String, String)]()
            while results.next() {
                let hymnID = Int(results.int(forColumn: "hymn_id"))
                updates.append((
                    hymnID,
                    LegacyCopticConverter.convertIfNeeded(results.string(forColumn: "hymn_name") ?? ""),
                    LegacyCopticConverter.convertIfNeeded(
                        LegacyCopticConverter.repairKnownOmissions(
                            results.string(forColumn: "hymn_coptic") ?? "",
                            hymnID: hymnID
                        )
                    )
                ))
            }
            results.close()

            guard database.beginTransaction() else { return }
            for (hymnID, name, copticText) in updates {
                guard database.executeUpdate(
                    "update hymn set hymn_name=?, hymn_coptic=? where hymn_id=?",
                    withArgumentsIn: [name, copticText, hymnID]
                ) else {
                    database.rollback()
                    print(database.lastErrorMessage())
                    return
                }
            }
            guard database.executeUpdate(
                "insert into app_migration(identifier) values (?)",
                withArgumentsIn: [migrationIdentifier]
            ) else {
                database.rollback()
                print(database.lastErrorMessage())
                return
            }
            database.commit()
        } catch {
            print("Coptic Unicode migration failed: \(error.localizedDescription)")
        }
    }

    // Open DB Funtion
    func pl_openDatabase() -> Bool {
        if pl_database == nil {
            
            //print("***** Path to Db \(pl_pathToDatabase)")
            
            if FileManager.default.fileExists(atPath: pl_pathToDatabase) {
                //print("Horray found file")
                pl_database = FMDatabase(path: pl_pathToDatabase)
            } else
            {
                print ("Cen't find file \(String(describing: pl_pathToDatabase))")
            }
        }
        
        if pl_database != nil {
            if pl_database.open() {
                return true
            }
        }
        
        return false
    }
    
    
    // Get DB Version
    func getDBVersion() -> Double {
        var version: Double!
        if openDatabase(){
        let query = "select version from version"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                //print("Query result \(results)")
                while results.next() {
                    version = results.double(forColumn: "version")
                    }

               
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
            
        }

    
        return version
    }
    
    // Get updates from DB
    func getLatestUpdates() -> String {
        var updates: String!
        if openDatabase(){
            let query = "select updates from version"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                //print("Query result \(results)")
                while results.next() {
                    updates = results.string(forColumn: "updates")
                }
                
                
            }
            catch {
                print(error.localizedDescription)
            }
            
            database.close()
            
        }
        
        
        return updates

    
    
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

    func loadSeasonHymns(WithID ID: Int) -> [SeasonHymns]{
        var seasonHymns = [SeasonHymns]()
        
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
                   
                    seasonHymns.append(seasonSection)
                    
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
    
    
    func loadHymnsForEvent(WithID ID: Int) -> [EventHymns]{
        var eventHymns: [EventHymns]!
        var dbOpen: Bool?
        
        
        // Due to the fact that we're making this call inside another DB connection
        // let's check if a connection exists, otherwise initiate it
        
        if !database.goodConnection {
            
            if  openDatabase() {
            dbOpen = true
            }
        }
       
            // this query will return all hymns for that event
            let query = "select * from hymn where hymn_event_id_fk=? order by hymn_order asc"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: [ID])
                //print("Query result \(results)")
                while results.next() {
                    
                    let hymn = EventHymns(hymnName: results.string(forColumn: "hymn_name"),
                                          hymnID: Int(results.int(forColumn: "hymn_id")),
                                          hymnDescription: results.string(forColumn: "hymn_desc"),
                                          hymnCoptic: results.string(forColumn: "hymn_coptic"),
                                          hymnEnglish: results.string(forColumn: "hymn_english"),
                                          hymnAudio: results.string(forColumn: "hymn_audio")
                        
                    )
                    //print ("$-$-$ Hymn \(hymn.hymnName)")
                    if eventHymns == nil {
                        eventHymns = [EventHymns]()
                    }
                    
                    eventHymns.append(hymn)
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
            
        
        
        return eventHymns
        
    }
    
    /// Which column a hymn search should match against. The on-screen keyboard that was
    /// used to type the query determines this: the Coptic keyboard only ever produces
    /// Coptic letters, and the system keyboard is only ever used to type English.
    enum HymnSearchField {
        case copticName
        case englishDescription
    }

    func searchHymns(matching searchText: String, field: HymnSearchField) -> [EventHymns] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, openDatabase() else { return [] }
        // Deliberately left open (unlike the other methods below): search fires once per
        // explicit "Search" tap rather than per keystroke, but reopening the sqlite file
        // on every search is still avoidable latency. `openDatabase()` is a cheap no-op
        // when the connection is already open, and any other call that still closes it
        // afterward is harmless — the next search just reopens it.

        // SQLite's built-in `COLLATE NOCASE` only case-folds ASCII A-Z, so a Coptic
        // hymn name that starts with a capital letter (the normal typographic
        // convention) never matched the on-screen keyboard's lowercase-only letters.
        // The stored names also carry combining accent marks (e.g. "Ⲧⲉⲛⲟ̀ⲩⲱ̀ϣⲧ") that
        // aren't available on that keyboard at all. Doing the match in Swift with
        // Unicode case- and diacritic-folding fixes both: it folds Coptic capitals to
        // lowercase correctly and strips the accents from both sides of the comparison.
        let normalizedQuery = normalizedForSearch(trimmedText)
        guard !normalizedQuery.isEmpty else { return [] }

        var hymns = [EventHymns]()
        do {
            // No WHERE clause here on purpose: the filtering happens below in Swift
            // since SQLite can't do Unicode-aware folding on its own. The hymn table
            // is small (a hymnal's worth of entries), so scanning it all is still fast.
            let results = try database.executeQuery(
                "select * from hymn order by hymn_name asc",
                values: nil
            )
            defer { results.close() }

            while results.next(), hymns.count < 50 {
                let name = results.string(forColumn: "hymn_name") ?? ""
                let description = results.string(forColumn: "hymn_desc") ?? ""
                // Which column to match against follows which keyboard was used to type
                // the query: the Coptic keyboard can only ever produce Coptic letters,
                // so it only makes sense to compare against the Coptic hymn name, and
                // likewise English input is only ever compared against the short
                // English description.
                let candidate = field == .copticName ? name : description
                guard normalizedForSearch(candidate).contains(normalizedQuery) else { continue }

                hymns.append(EventHymns(
                    hymnName: name,
                    hymnID: Int(results.int(forColumn: "hymn_id")),
                    hymnDescription: description,
                    hymnCoptic: results.string(forColumn: "hymn_coptic"),
                    hymnEnglish: results.string(forColumn: "hymn_english"),
                    hymnAudio: results.string(forColumn: "hymn_audio")
                ))
            }
        } catch {
            print(error.localizedDescription)
        }
        return hymns
    }

    /// Folds a string for accent- and case-insensitive matching. Unlike SQLite's
    /// ASCII-only `NOCASE`, Foundation's Unicode folding correctly lowercases Coptic
    /// capital letters and strips combining accent marks from Coptic vowels.
    private func normalizedForSearch(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    }

    func loadHymnDescription(withID hymnID: Int) -> String? {
        var openedDatabase = false

        if !database.goodConnection {
            guard openDatabase() else { return nil }
            openedDatabase = true
        }

        defer {
            if openedDatabase {
                database.close()
            }
        }

        do {
            let results = try database.executeQuery(
                "select hymn_desc from hymn where hymn_id=? limit 1",
                values: [hymnID]
            )
            defer { results.close() }
            return results.next() ? results.string(forColumn: "hymn_desc") : nil
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func loadHymnsURLS (hymnIDs: [Int]) -> [URL]{
        var hymnURLS: [URL] = []
        
        if openDatabase() {
            for hymnID in hymnIDs{
            let query = "select hymn_audio from hymn where hymn_id = \(hymnID)"
            
            do {
                //print(database)
                let results = try database.executeQuery(query, values: nil)
                //print("Query result \(results)")
                while results.next() {
                    let hymnURL = results.string(forColumn: "hymn_audio")
                    
                    
                    hymnURLS.append(URL(string: hymnURL!)!)
                    }
                }
            catch {
                print(error.localizedDescription)
                }
            }
            database.close()
            
        }
        
        return hymnURLS
        

    
    
    }

} // EOF

enum LegacyCopticConverter {
    private static let characterMap: [Character: String] = [
        "A": "Ⲁ", "a": "ⲁ", "B": "Ⲃ", "b": "ⲃ",
        "G": "Ⲅ", "g": "ⲅ", "D": "Ⲇ", "d": "ⲇ",
        "E": "Ⲉ", "e": "ⲉ", "Z": "Ⲍ", "z": "ⲍ",
        "?": "Ⲏ", "/": "ⲏ", "Y": "Ⲑ", "y": "ⲑ",
        "I": "Ⲓ", "i": "ⲓ", "K": "Ⲕ", "k": "ⲕ",
        "L": "Ⲗ", "l": "ⲗ", "M": "Ⲙ", "m": "ⲙ",
        "N": "Ⲛ", "n": "ⲛ", "X": "Ⲝ", "x": "ⲝ",
        "O": "Ⲟ", "o": "ⲟ", "P": "Ⲡ", "p": "ⲡ",
        "R": "Ⲣ", "r": "ⲣ", "C": "Ⲥ", "c": "ⲥ",
        "T": "Ⲧ", "t": "ⲧ", "U": "Ⲩ", "u": "ⲩ",
        "V": "Ⲫ", "v": "ⲫ", "J": "Ϫ", "j": "ϫ", "<": "Ⲭ",
        "\"": "Ⲯ", "'": "ⲯ", "W": "Ⲱ", "w": "ⲱ",
        "S": "Ϣ", "s": "ϣ", "F": "Ϥ", "f": "ϥ",
        "Q": "Ϧ", "q": "ϧ", "H": "Ϩ", "h": "ϩ", "{": "Ϭ", "[": "ϭ",
        "}": "Ϯ", "]": "ϯ", ",": "ⲭ"
    ]

    private static let abbreviationMap: [Character: String] = [
        "0": "ⲉ̅ⲑ̅ⲩ̅",
        "5": "⳪",
        "7": "\u{0305}ⲏ̅ⲥ̅",
        "8": "ⲭ̅ⲥ̅",
        "9": "ⲡ̅ⲛ̅ⲁ̅",
        "*": "ⲁ̅ⲗ̅"
    ]

    private static let punctuationMap: [Character: String] = [
        "&": ";",
        "~": ".",
        "@": ":",
        ">": ",",
        "|": "ⳉ",
        "¡": "⳪",
        "¢": "⳥",
        "¤": "⳨",
        "¥": "⳩",
        "½": "⳧",
        "¾": "⳧"
    ]

    static func repairKnownOmissions(_ legacyText: String, hymnID: Int) -> String {
        guard hymnID == 2, !legacyText.contains("Ari`precbeuin") else { return legacyText }

        let missingParagraphs = """


        Ari`precbeuin `e`hr/i `ejwn nahren P8 v/`etare`jvof hopwc `ntefer`hmot nan `mpi,w `ebol `nte nennobi.

        <ere ne `w ]Paryenoc ]ourw `mm/i `n`al/yin/ ,ere `psousou `nte pengenoc are`jvo nan `nEmmanou/l.

        Ten]ho `arepenmeu`i `w ]`proctat/c `etenhot nahren pen5 I7 P8 `ntef,a nennobi nan `ebol.
        """
        return legacyText + missingParagraphs
    }

    static func convertIfNeeded(_ text: String) -> String {
        let alreadyUsesUnicodeCoptic = text.unicodeScalars.contains { scalar in
            (0x2C80...0x2CFF).contains(scalar.value)
                || (0x03E2...0x03EF).contains(scalar.value)
        }
        return alreadyUsesUnicodeCoptic ? text : convert(text)
    }

    static func convert(_ legacyText: String) -> String {
        var converted = ""
        var pendingDiacritic: String?

        for character in legacyText {
            if character == "`" {
                pendingDiacritic = "\u{0300}"
                continue
            }
            if character == "=" {
                pendingDiacritic = "\u{0305}"
                continue
            }

            let mapped: String
            if character == "\\" {
                mapped = "ⲟⲩ"
            } else if let coptic = characterMap[character] {
                mapped = coptic
            } else if let abbreviation = abbreviationMap[character] {
                mapped = abbreviation
            } else if let punctuation = punctuationMap[character] {
                mapped = punctuation
            } else {
                mapped = String(character)
            }

            converted += mapped
            if let diacritic = pendingDiacritic {
                converted += diacritic
                pendingDiacritic = nil
            }
        }

        if let pendingDiacritic {
            converted += pendingDiacritic
        }
        return converted.precomposedStringWithCanonicalMapping
    }

}
