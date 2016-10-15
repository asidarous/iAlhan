//
//  SeasonDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

public struct SeasonHymns {
    //var hymnName: String!
    var seasonSections: [String: [String]]!
}

struct EventHymns {
    var hymnName: String!
    //var hymnID: Int!
    //var hymnDescrition: String!
}

class SeasonDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    // Model: an album
    //var album: Season?
    //var seasonHymnsStruct: SeasonHymns?
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!

    @IBOutlet var tableView: UITableView!

    var arrayCount: Int?
    var hymnArray: [Any] = []
    let textCellIdentifier = "TextCell"
    var labelText: String?
    
    struct structureArray {
        var sectionName: String!
        var sectionDetails: [String]!
    }
    
    var objectArray = [structureArray]()

   
   
    func updateUI()
    {
        
        //print (album!.seasonSections?.count)
        
        //if album?.seasonSections?.count != nil {
        //hymnArray = (album?.seasonSections)!
        //}
        arrayCount = hymnArray.count
        tableView.delegate = self
        tableView.dataSource = self
        
        //print ("Array count \(arrayCount)")
        //print (hymnArray.description)
        
        
        for (index, _) in hymnArray.enumerated() {
            
            //print("\(index) -> \(item)")
            //print( hymnArray[index])
            let arrayText =  (hymnArray[index] as! NSDictionary)
            
            for (key, value) in arrayText{
                //print ("Key and Value info \(key) ------ > \(value)")
                objectArray.append(structureArray(sectionName: key as! String, sectionDetails: value as! [String]))
            }
            
        }
        
        // print("OBJECT ARRAY COUNT \(objectArray.count)")
       
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        updateUI()
        //print ("Label Text \(labelText)")
        title = labelText
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // get rid of the background image from superview
        backgroundImageView.removeFromSuperview()
        //visualEffectView.removeFromSuperview()

    }
    
 
    
    // MARK:  UITableViewDelegate Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (objectArray.count)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return (objectArray[section].sectionDetails?.count)!
    }
    
   func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //print ("header for section: \(section)")
        
        let rawDescription = objectArray[section].sectionName.description
        
        //let range = rawDescription.index(rawDescription.startIndex, offsetBy: 4)..<rawDescription.endIndex

        return (rawDescription) as String
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath as IndexPath)
        
        let row = indexPath.row
        let section = indexPath.section
        // cell.textLabel?.text = (hymnArray?[row].seasonSections)! as String
        cell.textLabel?.text = (objectArray[section].sectionDetails[row].description) as String
        cell.detailTextLabel?.text = "Testing this"
        return cell
    }
    
    
 /*   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let row = indexPath.row
        let section = indexPath.section
        
        print(objectArray[section].sectionDetails[row].description)
    }
    */
    
    // MARK: - Target/Action
    
    @IBAction func showHymn(_ sender: UITapGestureRecognizer)
    {
        performSegue(withIdentifier: "Show Hymn Detail", sender: sender.view)
        
    }
    
    // MARK: - Navigation
    
//   override func prepare(for segue: UIStoryboardSegue, sender: Any?)
//    {
//        if let identifier = segue.identifier
//        {
//            switch identifier
//            {
//            case "Show Hymn Detail":
//                //print ("I'm here")
//                let hymnDetailVC = segue.destination as! HymnDetailViewController, blogIndex = tableView.indexPathForSelectedRow?.row
//                
//                {
//                    //print ("Index: ")
//                    //print (index)
//                    let hymn = Season.init(index: index)
//                    hymnDetailVC.album = album
//                    
//                }
//                
//                
//            default:
//                break
//                
//                
//            }
//        }
//    }

   
    
}


