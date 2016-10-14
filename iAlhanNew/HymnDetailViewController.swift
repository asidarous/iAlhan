//
//  HymnDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/11/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class HymnDetailViewController: UIViewController {
    @IBOutlet var HymnText: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    var HymnName = String()
    
    override func viewWillAppear(_ animated: Bool) {
        HymnText.text = HymnName
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
