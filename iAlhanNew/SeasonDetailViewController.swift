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
        print (album?.title)
        
        hymnArray = (album?.seasonSections)! as Dictionary <String, [String]>
        arrayCount = hymnArray?.count
        tableView.delegate = self
        tableView.dataSource = self
       
        print (hymnArray?.count)
        //print (hymnArray)
       
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let test = (album?.seasonSections)! as Dictionary <String, [String]>
        print (test)
//        
       
        
        
        for (key, value) in test {
            print("\(key) -> \(value)")
            objectArray.append(structureArray(sectionName: key, sectionDetails: value))
            
        }
        
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
        print ("header for section: \(section)")
        return (objectArray[section].sectionName.description) as String
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath as IndexPath)
        
        let row = indexPath.row
        let section = indexPath.section
        //cell.textLabel?.text = (hymnArray?[row]) as! String
        cell.textLabel?.text = (objectArray[section].sectionDetails[row].description) as String
        
        return cell
    }
    
    
    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let row = indexPath.row
        print(objectArray[row])
    }
    
    
    
}


