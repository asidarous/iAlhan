//
//  SeasonDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class SeasonDetailViewController: UIViewController {

    // Model: an album
    var album: Season?
    
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!




    func updateUI()
    {
        print("Title")
        print (album?.title)
        let hymnList = ((album?.seasonSections)! as NSArray).componentsJoined(by: ", ")
        detailTextView.text = hymnList
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
}


