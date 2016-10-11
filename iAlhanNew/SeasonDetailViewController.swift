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
    var hymnArray: NSArray?
    let textCellIdentifier = "TextCell"

    

    func updateUI()
    {
        print("Title")
        print (album?.title)
        
        hymnArray = (album?.seasonSections)! as NSArray

        arrayCount = hymnArray?.count
        tableView.delegate = self
        tableView.dataSource = self
       
        print (hymnArray?.count)
        print (hymnArray)
       
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
    
 
    
    // MARK:  UITextFieldDelegate Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return (hymnArray?.count)!
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (hymnArray?.count)!
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath as IndexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = hymnArray?[row] as? String
        
        return cell
    }
    
    // MARK:  UITableViewDelegate Methods
    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let row = indexPath.row
        print(hymnArray?[row])
    }
    
     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section"
    }
    
}


