//
//  ContactVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 4/1/17.
//  Copyright © 2017 alhan.org. All rights reserved.
//

import UIKit
import MessageUI

class ContactVC: UIViewController, @preconcurrency MFMailComposeViewControllerDelegate {

    @IBOutlet var nameField: UITextField!

    @IBOutlet var emailField: UITextField!

    @IBOutlet var messageField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.configureCreamBackground(for: view)
        AppAppearance.configureNavigationBar(for: self)
        [nameField, emailField, messageField].forEach(AppAppearance.configureTextField)
        nameField.textContentType = .name
        emailField.textContentType = .emailAddress
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        messageField.accessibilityLabel = "Message"
        styleFormControls(in: view)
    }

    private func styleFormControls(in rootView: UIView) {
        for subview in rootView.subviews {
            if let label = subview as? UILabel {
                label.font = UIFont.preferredFont(forTextStyle: .headline)
                label.adjustsFontForContentSizeCategory = true
                label.textColor = .label
            } else if let button = subview as? UIButton, button.buttonType == .system {
                AppAppearance.configurePrimaryButton(button)
                continue
            }
            styleFormControls(in: subview)
        }
    }
    
    
    
    
    
    @IBAction func sendEmail(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
        let toRecepients = ["arsani@alhan.org"]
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        
        mc.setToRecipients(toRecepients)
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        mc.setSubject("iAlhan message from: \(name)")
        mc.setMessageBody("Name: \(name)<br/>Email: \(email)<br/>Message: \(message)", isHTML: true)
        
        self.present(mc,animated: true, completion: nil)
        }else {
        
            let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send Email.  Please check Email configuration and try again.", preferredStyle: UIAlertController.Style.alert)
            sendMailErrorAlert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
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
