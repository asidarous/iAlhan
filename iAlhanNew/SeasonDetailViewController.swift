//
//  SeasonDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class SeasonDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    // Model: an album
    var album: Season?
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!

    @IBOutlet var tableView: UITableView!

    
    var arrayCount: Int?
    var hymnArray: [String: [String]]?
    let textCellIdentifier = "TextCell"
    
    struct structureArray {
        var sectionName: String!
        var sectionDetails: [String]!
    }
    
    var objectArray = [structureArray]()

   
   
    func updateUI()
    {
        print("Title")
        print (album!.title)
        
        hymnArray = (album?.seasonSections)!
        
        arrayCount = hymnArray?.count
        tableView.delegate = self
        tableView.dataSource = self
        
        for (key, value) in hymnArray! {
            //print("\(key) -> \(value)")
            objectArray.append(structureArray(sectionName: key, sectionDetails: value))
            
        }
        
        
    // sorting the section array as for some reason it has a mind of its own
        objectArray.sort {$0.sectionName < $1.sectionName}
       
    // debug print statement
        /* print (hymnArray?.count)
        print ("ORIGINAL.....\(hymnArray)")
        print ("ORIGINAL SORTED.....\(objectArray)") */
       
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = ((album?.title)!)
        updateUI()
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
        
        let range = rawDescription.index(rawDescription.startIndex, offsetBy: 4)..<rawDescription.endIndex

        return (rawDescription[range]) as String
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath as IndexPath)
        
        let row = indexPath.row
        let section = indexPath.section
        cell.textLabel?.text = (objectArray[section].sectionDetails[row].description) as String
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let row = indexPath.row
        let section = indexPath.section
        
        print(objectArray[section].sectionDetails[row].description)
    }
    
    
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


