//
//  HymnLibrary.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/11/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import Foundation

struct HymnLibrary
{
    // title: String
    // hymnEnglishText: String
    
    let hymnDetail : [String : Any] = [
        "title" : "Hymn 1",
        "hymnEnglishText" : "This is the text in English for the hymn",
        
    ]
    
    let hymnDetails: [[String: Any]] = [
        
        [
            "title" : "Hymn 1",
            "seasonImage" : "epiphany",
           
        ],
        [
            "title" : "Hymn 2",
            "seasonImage" : "theotokos_sml_rnd",
        ]
    ]
}
