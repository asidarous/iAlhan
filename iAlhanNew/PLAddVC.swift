//
//  PLAddVC.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 10/28/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class PLAddVC: UIViewController, UITextFieldDelegate {

    @IBOutlet var plText: UITextField!
   
    //
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.configureCreamBackground(for: view)
        AppAppearance.configureNavigationBar(for: self)
        AppAppearance.configureTextField(plText)
        plText.accessibilityLabel = "Playlist name"
        plText.returnKeyType = .done
        plText.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
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
        createPlaylist()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createPlaylist()
        return true
    }

    private func createPlaylist() {
        guard let playlistName = plText.text, !playlistName.isEmpty else { return }

        if PL_DBManager.shared.createPL(playlist: playlistName) {
            dismiss(animated: true)
        } else {
            let alert = UIAlertController(
                title: "Playlist name is already used",
                message: "Please select a different name",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let formView = plText.superview,
              let endFrame = notification.userInfo?[
                UIResponder.keyboardFrameEndUserInfoKey
              ] as? CGRect else { return }

        formView.transform = .identity
        let keyboardFrame = view.convert(endFrame, from: nil)
        let formFrame = formView.convert(formView.bounds, to: view)
        let overlap = max(0, formFrame.maxY + 12 - keyboardFrame.minY)
        let availableLift = max(
            0,
            formFrame.minY - view.safeAreaInsets.top - 12
        )
        updateFormTransform(
            y: -min(overlap, availableLift),
            notification: notification
        )
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        updateFormTransform(y: 0, notification: notification)
    }

    private func updateFormTransform(
        y: CGFloat,
        notification: Notification
    ) {
        let duration = notification.userInfo?[
            UIResponder.keyboardAnimationDurationUserInfoKey
        ] as? TimeInterval ?? 0.25
        let curveValue = notification.userInfo?[
            UIResponder.keyboardAnimationCurveUserInfoKey
        ] as? UInt ?? 0
        let options = UIView.AnimationOptions(
            rawValue: curveValue << 16
        )

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options
        ) {
            self.plText.superview?.transform = CGAffineTransform(
                translationX: 0,
                y: y
            )
        }
    }

    @IBAction func Cancel(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
