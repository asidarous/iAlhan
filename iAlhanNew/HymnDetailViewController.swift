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

        // Do any additional setup after loading the view.
    }

    
    
    override func viewWillAppear(_ animated: Bool) {
        HymnText.text = hymnDetail?[0].hymnCoptic
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
