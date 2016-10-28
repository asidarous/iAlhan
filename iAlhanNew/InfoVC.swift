//
//  InfoVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 10/27/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class InfoVC: UIViewController {

    @IBOutlet var DataView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        DataView.layer.cornerRadius = 30
        DataView.layer.shadowColor = UIColor.black.cgColor
        DataView.layer.shadowOpacity = 0.7
        DataView.layer.shadowOffset = CGSize.init(width: 1, height: 1)
        DataView.layer.shadowRadius = 2
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        
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
