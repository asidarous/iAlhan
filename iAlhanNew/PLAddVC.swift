//
//  PLAddVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 10/28/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class PLAddVC: UIViewController {

    @IBOutlet var plText: UITextField!
   
    //
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        plText.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool){
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
    
    }
    
    @IBAction func AddPL(_ sender: AnyObject) {
        
        if plText.text != "" {
            PL_DBManager.shared.createPL(playlist: plText.text!)
            self.dismiss(animated: true, completion: nil)
        }
        
        
    }

    @IBAction func Cancel(_ sender: AnyObject) {
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
