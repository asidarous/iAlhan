//
//  HymnDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/11/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

struct HymnDetail {
    var hymnName: String!
    var hymnID: Int!
    var hymnDescription: String!
    var hymnCoptic: String!
    var hymnEnglish: String!
    var hymnAudio: String!
}

class HymnDetailViewController: UIViewController {
    @IBOutlet var HymnText: UITextView!
    @IBOutlet var ToolBar: UIToolbar!



    var pauseButton = UIBarButtonItem()
    var playButton = UIBarButtonItem()
    var arrayOfButtons = [UIBarButtonItem]()

    var hymnDetail: [EventHymns]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = hymnDetail?[0].hymnName
       
        ToolBar.tintColor = GlobalConstants.kColor_DarkColor
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(HymnDetailViewController.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(HymnDetailViewController.playButtonTapped))
        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.insert(playButton, at: 0) // change index to wherever you'd like the button
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
        
//
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    func playButtonTapped() {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(pauseButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }
    
    func pauseButtonTapped() {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(playButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
         HymnText.setContentOffset(CGPoint.zero, animated: false)
    }

    var originalStyle: [String: Any]!
    
    override func viewWillAppear(_ animated: Bool) {
        HymnText.text = hymnDetail?[0].hymnCoptic
        
        
        originalStyle = navigationController?.navigationBar.titleTextAttributes?.lazy.elements
        print(originalStyle)
        
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "copt", size: 24)!, NSForegroundColorAttributeName: GlobalConstants.kColor_GoldColor]
           }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        navigationController?.navigationBar.titleTextAttributes = originalStyle
        
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
