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


    var hymnDetail: [EventHymns]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = hymnDetail?[0].hymnName
        
//
        
        
        // Do any additional setup after loading the view.
    }

    var originalStyle: [String: Any]!
    
    override func viewWillAppear(_ animated: Bool) {
        HymnText.text = hymnDetail?[0].hymnCoptic
        
        
        originalStyle = navigationController?.navigationBar.titleTextAttributes?.lazy.elements
        print(originalStyle)
        
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "copt", size: 24)!, NSForegroundColorAttributeName: UIColor(red: CGFloat(255/255.0), green: CGFloat(223/255.0), blue: CGFloat(107/255.0), alpha: CGFloat(1.0) )
            //. .init(red: 1.00205, green: 0.891642, blue: 0.492594, alpha: 1)
        ]
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
