//
//  Downloader.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 3/31/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import Foundation
import UIKit


    func downloadDBFile(){
        // Create destination URL
        let documentsUrl:URL = URL(string: Bundle.main.path(forResource: "AlhanSQL3", ofType: "sqlite")!)! as URL
        print ("DOCUMENTS URL \(documentsUrl)---")
            //FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        //let destinationFileUrl = documentsUrl.appendingPathComponent("AlhanSQL.sqlite")
        
        //Create URL to the source file you want to download
        let fileURL = URL(string: "http://www.alhan.org/ialhan/version3/AlhanSQL3.sqlite")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL!)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }
                
                // Delete existing file
                do {
                    try FileManager.default.removeItem(atPath: documentsUrl.path)
                } catch (let writeError) {
                    print("Error deleting a file \(documentsUrl) : \(writeError)")
                }
                
                // Copy the downloaded file
                do {
                    try FileManager.default.copyItem(atPath: tempLocalUrl.path, toPath: documentsUrl.path)
                    //copyItem(atPath: tempLocalUrl, toPath: documentsUrl)
                } catch (let writeError) {
                    print("Error creating a file \(documentsUrl) : \(writeError)")
                }
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
            }
        }
        task.resume()
        
    }

// Update alert box
func showUpdateAlertButton(in vc: UIViewController) {
    let message = DBManager.shared.getLatestUpdates()
    let newMessage = message.replacingOccurrences(of: ",", with: "\n")
    let alert = UIAlertController(title: "New Hymns Added", message: newMessage, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    vc.present(alert, animated: true, completion: nil)
}



