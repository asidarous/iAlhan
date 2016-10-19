//
//  HymnDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/11/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit
import AVFoundation

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
    @IBOutlet var ToolBar: UIToolbar!
    @IBOutlet var ProgressBar: UISlider!

    var pauseButton = UIBarButtonItem()
    var playButton = UIBarButtonItem()
    var arrayOfButtons = [UIBarButtonItem]()

    var hymnDetail: [EventHymns]?
    
    var alhanPlayer = AVPlayer()
    var playerItem: AVPlayerItem!
    var hymnAudioURL: NSURL!
    var error:NSError?
    
    var asset:AVAsset?
    
    var updater : CADisplayLink! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = hymnDetail?[0].hymnName
        hymnAudioURL = NSURL(string: (hymnDetail?[0].hymnAudio)!)

        
        playerItem = AVPlayerItem(url: hymnAudioURL as URL)
        self.alhanPlayer = AVPlayer(playerItem: playerItem)
        
        //print("PLAYER ITEM At view Did Load : -- \(playerItem)")
        ToolBar.tintColor = GlobalConstants.kColor_DarkColor
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(HymnDetailViewController.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(HymnDetailViewController.playButtonTapped))
        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.insert(playButton, at: 0) // change index to wherever you'd like the button
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
    }
    
    func play() {

            //updater = CADisplayLink(target: self, selector: #selector(HymnDetailViewController.trackAudio))
            //updater.preferredFramesPerSecond = 1
            //updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
            alhanPlayer.volume = 1.0
            alhanPlayer.play()

    }
    
    
    func pause() {

            alhanPlayer.volume = 1.0
            alhanPlayer.pause()
    }
    
    func playButtonTapped() {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(pauseButton, at: 0)

        play()

        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }
    
    func pauseButtonTapped() {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(playButton, at: 0)
        
        pause()
       
        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }

    
    // tracking audio
    func trackAudio() {
        let normalizedTime = Float((alhanPlayer.currentTime().seconds) * 100 / (alhanPlayer.currentItem?.duration.seconds)!)
        ProgressBar.value = normalizedTime
    }
   
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
         HymnText.setContentOffset(CGPoint.zero, animated: false)
    }

    var originalStyle: [String: Any]!
    
    override func viewWillAppear(_ animated: Bool) {
        HymnText.text = hymnDetail?[0].hymnCoptic
        
        
        originalStyle = navigationController?.navigationBar.titleTextAttributes?.lazy.elements
        //print(originalStyle)
        
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "copt", size: 24)!, NSForegroundColorAttributeName: GlobalConstants.kColor_GoldColor]
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
