//
//  CheckVersion.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 3/31/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import Foundation


@MainActor
func CheckVersion () -> Bool {
    
    // local version
    let localDBVersion = DBManager.shared.getDBVersion()
    print("Local DB Version: \(localDBVersion)")

    // internet version
    guard let url = URL(string: "http://www.alhan.org/ialhan/version3/dbversion3.txt") else {
        return false
    }

    let internetContent: String
    do {
        internetContent = try String(contentsOf: url, encoding: .utf8)
        print("Here is the version from the web: \(internetContent)")
    } catch {
        print("Unable to check the remote DB version: \(error.localizedDescription)")
        return false
    }
    
    // Only download when the server is newer. A bundled development database
    // can legitimately be ahead of production and must never be downgraded.
    guard let remoteVersion = Double(
        internetContent.trimmingCharacters(in: .whitespacesAndNewlines)
    ) else {
        print("Unable to parse remote DB version")
        return false
    }

    if remoteVersion > localDBVersion {
        print("A newer database is available")
        downloadDBFile()
        return true
    }

    print("Version is current")
    return false
}
