//
//  CheckVersion.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 3/31/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import Foundation


func CheckVersion () -> Bool {
    
    var internetContent: String!
    
    // local version
    let localDBVersion = DBManager.shared.getDBVersion()
    print("Local DB Version: \(localDBVersion)")
    
    // internet version
    let url = URL(string: "http://www.alhan.org/ialhan/version3/dbversion3.txt")
    do {
        // Get the contents
        internetContent = try String(contentsOf: url!)
        print("Here is the version from the web: \(String(describing: internetContent))")
    }
    catch let error as NSError {
        print("Ooops! Something went wrong: \(error)")
    }
    
    // if version is different update local

    if localDBVersion != Double(internetContent)
    {
        print ("They are not equal")
        downloadDBFile()
        return true
        
    }else{
        print ("Version is current")
        return false
    }
}
