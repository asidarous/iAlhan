//
//  FileUtils.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/20/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import Foundation
import UIKit


    
    func getDirectory(url: String) -> String{
        
        
        let tempArray = url.components(separatedBy: "/")
        let arrayCount = tempArray.count
        let fileName = tempArray[arrayCount-1]
        let prefix = tempArray[0]+"//"+tempArray[2]+"/"
        let start = url.index((url.startIndex), offsetBy: prefix.count)
        let end = url.index((url.endIndex), offsetBy: -(fileName.count))
        let range = start..<end
        let directory = url.substring(with: range)
        return directory
    
    }


