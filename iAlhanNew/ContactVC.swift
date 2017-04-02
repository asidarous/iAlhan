//
//  ContactVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 4/1/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import UIKit
import MessageUI

class ContactVC: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet var nameField: UITextField!

    @IBOutlet var emailField: UITextField!

    @IBOutlet var messageField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
    
    
    @IBAction func sendEmail(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
        let toRecepients = ["arsani@alhan.org"]
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        
        mc.setToRecipients(toRecepients)
        mc.setSubject("iAlhan message from: \(nameField.text!)")
        mc.setMessageBody("Name: \(nameField.text!)\n\n Email: \(emailField.text!) \n\n Message: \(messageField.text!)", isHTML: true)
        
        self.present(mc,animated: true, completion: nil)
        }else {
        
            let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send Email.  Please check Email configuration and try again.", preferredStyle: UIAlertControllerStyle.alert)
            sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
             self.present(sendMailErrorAlert, animated: true, completion: nil)
            

        }
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        self.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func dismissKeyboard(_ sender: Any) {
        self.resignFirstResponder()
    }
    
    @IBAction func done(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        
    }
}
