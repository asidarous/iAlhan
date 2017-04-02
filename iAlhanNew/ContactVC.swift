//
//  ContactVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 4/1/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import UIKit

class ContactVC: UIViewController {

    @IBOutlet var nameField: UITextField!

    @IBOutlet var emailField: UITextField!

    @IBOutlet var messageField: UITextView!

    @IBAction func sendEmail(_ sender: Any) {
    }
    
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
