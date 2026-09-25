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
        AppAppearance.configureCreamBackground(for: view)
        AppAppearance.configureNavigationBar(for: self)
        DataView.backgroundColor = .secondarySystemGroupedBackground
        DataView.layer.cornerRadius = 24
        DataView.layer.cornerCurve = .continuous
        DataView.layer.shadowColor = UIColor.black.cgColor
        DataView.layer.shadowOpacity = 0.12
        DataView.layer.shadowOffset = CGSize(width: 0, height: 8)
        DataView.layer.shadowRadius = 18
        styleContent(in: DataView)
        // Do any additional setup after loading the view.
    }

    private func styleContent(in rootView: UIView) {
        for subview in rootView.subviews {
            if let label = subview as? UILabel {
                label.adjustsFontForContentSizeCategory = true
                label.textColor = .label
            } else if let textView = subview as? UITextView {
                textView.font = UIFont.preferredFont(forTextStyle: .body)
                textView.adjustsFontForContentSizeCategory = true
                textView.textColor = .label
                textView.backgroundColor = .clear
            } else if let button = subview as? UIButton {
                button.tintColor = GlobalConstants.kColor_DarkColor
                button.titleLabel?.adjustsFontForContentSizeCategory = true
            }
            styleContent(in: subview)
        }
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
