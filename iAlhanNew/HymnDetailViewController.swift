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

class HymnDetailViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var ToolBar: UIToolbar!
    @IBOutlet var HymnTextEnglish: UITextView!
    @IBOutlet var HymnTextCoptic: UITextView!

    
    
     @IBOutlet var ProgressBar: UISlider!

    var pauseButton = UIBarButtonItem()
    var playButton = UIBarButtonItem()
    var saveButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    
    
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
        
        HymnTextEnglish.delegate = self
        HymnTextCoptic.delegate = self

        title = hymnDetail?[0].hymnName
        hymnAudioURL = NSURL(string: (hymnDetail?[0].hymnAudio)!)

        
        //new progress bar
        ProgressBar = UISlider(frame:CGRect(x: 10, y: 100, width: 280, height: 20))
        ProgressBar.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        ProgressBar.thumbTintColor = GlobalConstants.kColor_DarkColor
        ProgressBar.isUserInteractionEnabled = true
        
        ProgressBar.addTarget(self, action: #selector(HymnDetailViewController.Seek), for: .allEvents)
        ProgressBar.sizeToFit()

        
        playerItem = AVPlayerItem(url: hymnAudioURL as URL)
        self.alhanPlayer = AVPlayer(playerItem: playerItem)
        
        //print("PLAYER ITEM At view Did Load : -- \(playerItem)")
        ToolBar.tintColor = GlobalConstants.kColor_DarkColor
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(HymnDetailViewController.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(HymnDetailViewController.playButtonTapped))
        saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.organize, target: self, action: #selector(HymnDetailViewController.saveFile))
       
        let flexible = UIBarButtonItem(customView: ProgressBar)
        
        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.insert(playButton, at: 0) // change index to wherever you'd like the button
        arrayOfButtons.insert(flexible, at: 1)
        arrayOfButtons.insert(saveButton, at: 2)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
      
        
        
        ProgressBar.minimumValue = 0
        //ProgressBar.maximumValue = 100
            //Float((alhanPlayer.currentItem?.duration.seconds)!)
        
    }
    
    // MARK: Scroll control
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == HymnTextCoptic{
            HymnTextEnglish.contentOffset = HymnTextCoptic.contentOffset
        }else{
            HymnTextCoptic.contentOffset = HymnTextEnglish.contentOffset
        }
    }

    // MARK: Audio controls
    
    func finishedPlaying(myNotification: Notification ){
        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        //print("IMGONACHANGEIT------------")
        arrayOfButtons.insert(playButton, at: 0)
        //self.ProgressBar.value = 0.0
        
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        updater.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
        
        resetBar()
        
    }
    
    func play() {

            updater = CADisplayLink(target: self, selector: #selector(HymnDetailViewController.trackAudio))
            updater.preferredFramesPerSecond = 60
            updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
            alhanPlayer.volume = 1.0
            //print("------ \(alhanPlayer.currentItem?.duration.seconds)")
            ProgressBar.maximumValue = Float((alhanPlayer.currentItem?.duration.seconds)!)
            alhanPlayer.play()

    }
    
    
    func pause() {

            alhanPlayer.volume = 1.0
            alhanPlayer.pause()
    }
    
    func resetBar(){
        alhanPlayer.currentItem?.seek(to: CMTimeMake(0,1))
        //ProgressBar.value = Float(0)
    
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

    
    // MARK: tracking audio
    func trackAudio() {
        //let normalizedTime = Float((alhanPlayer.currentTime().seconds) * 100 / (alhanPlayer.currentItem?.duration.seconds)!)

        ProgressBar.value = Float((alhanPlayer.currentTime().seconds))
        //normalizedTime
        
    }
    
    @IBAction func Seek(_ sender: UISlider) {
        
        alhanPlayer.pause()
        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(playButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
        alhanPlayer.seek(to: CMTimeMake(( Int64(ProgressBar.value)), 1) )
        //alhanPlayer.play()
        play()
        
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(pauseButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
    }
    
    

    
    // MARK: file handling
    
    func saveFile(){
    }
   
    func deleteFile(){
    }
    
    
    
    // MARK: View Functions
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
         HymnTextCoptic.setContentOffset(CGPoint.zero, animated: false)
        HymnTextEnglish.setContentOffset(CGPoint.zero, animated: false)
    }

    var originalStyle: [String: Any]!
    
    override func viewWillAppear(_ animated: Bool) {
        HymnTextCoptic.text = hymnDetail?[0].hymnCoptic
        HymnTextEnglish.text = hymnDetail?[0].hymnEnglish
        
        originalStyle = navigationController?.navigationBar.titleTextAttributes?.lazy.elements
        //print(originalStyle)
        
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "copt", size: 24)!, NSForegroundColorAttributeName: GlobalConstants.kColor_GoldColor]
        
        NotificationCenter.default.addObserver(self, selector: #selector(HymnDetailViewController.finishedPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

           }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        navigationController?.navigationBar.titleTextAttributes = originalStyle
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
