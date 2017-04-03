//
//  HymnDetailViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/11/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

struct HymnDetail {
    var hymnName: String!
    var hymnID: Int!
    var hymnDescription: String!
    var hymnCoptic: String!
    var hymnEnglish: String!
    var hymnAudio: String!
}

var playlistInstructions: Bool = false
class HymnDetailViewController: UIViewController, UITextViewDelegate{
    @IBOutlet var HymnDetailView: UIView!

    @IBOutlet var ToolBar: UIToolbar!
    @IBOutlet var HymnTextEnglish: UITextView!
    @IBOutlet var HymnTextCoptic: UITextView!
    
    var progressBar: UISlider!
    var progressBarLabel: UILabel!

    var pauseButton = UIBarButtonItem()
    var playButton = UIBarButtonItem()
    var saveButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    
    
    var arrayOfButtons = [UIBarButtonItem]()

    var hymnDetail: [EventHymns]?
    

    var playerItem: AVPlayerItem!
    var hymnAudioURL: URL!
    var error:NSError?
    
    var asset:AVAsset?
    
    //var updater : CADisplayLink! = nil
    
    var localDir: String!
    var fileIsLocal: Bool = false
    
    let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    
    // Internet alert box
    @IBAction func showAlertButton() {
    let alert = UIAlertController(title: "No Internet Connection", message: "Please make sure you are connected to the internet to be able to stream hymns. Meanwhile you can listen to downloaded content offline. ", preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "crossbck_sml")!)
        
        
        if (self.canBecomeFirstResponder){
            self.becomeFirstResponder()
        }
        // MARK: Swipe controls
        let recognizer: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector (swipeLeft(recognizer:)))
        recognizer.direction = .left
        self.view .addGestureRecognizer(recognizer)
        
        
        
        // handles audio when device is muted
        do {
            
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.allowAirPlay)
            } else {
                // Fallback on earlier versions
            }//.mixWithOthers)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            try AVAudioSession.sharedInstance().setActive(true)
            
        }
        catch {
            print(error)
        }


        // file download handling
        //print("8888888888" )
        //print ((hymnDetail?[0].hymnAudio)!)
        localDir = getDirectory(url: (hymnDetail?[0].hymnAudio)!)
        //print("DIRECTORY \(localDir)")
        
        HymnTextEnglish.delegate = self
        HymnTextCoptic.delegate = self

        title = hymnDetail?[0].hymnName
        hymnAudioURL = URL(string: (hymnDetail?[0].hymnAudio)!)
        
        // check to see if the file is local and thus play from local
        let localPath = documentsDirectoryURL.appendingPathComponent(localDir)
        let destinationUrl = localPath.appendingPathComponent((hymnAudioURL?.lastPathComponent)!)
        
        if FileManager.default.fileExists(atPath: destinationUrl.path){
            hymnAudioURL = destinationUrl
            fileIsLocal = true
            // print("!!!!!! playing the local file - TOP")
        }
        
        //new progress bar
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(HymnDetailViewController.trackAudio), userInfo: nil, repeats: true)
        
        //Get progress bar width based on orientation
        var pbWidth: CGFloat!
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact
            print("%%%% I'm compact")
            
            pbWidth = HymnDetailView.frame.width * 0.65
            print("WIDTH: \(pbWidth)")
            
        } else {
            // Regular
            print("%%%% I'm regular")
           pbWidth = HymnDetailView.frame.width * 0.82
           print("WIDTH: \(pbWidth)") 
        }
        
        //pbWidth = HymnDetailView.frame.width * 0.85
        print("The width: \(pbWidth)")
        progressBar = UISlider(frame:CGRect(x: 10, y: 100, width: pbWidth, height: 20))
        progressBar.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        progressBar.thumbTintColor = GlobalConstants.kColor_DarkColor
        progressBar.setThumbImage(UIImage(named: "thumb"), for: UIControlState.normal)
        progressBar.setThumbImage(UIImage(named: "thumb"), for: UIControlState.highlighted)
        progressBar.isUserInteractionEnabled = true
        
        progressBar.addTarget(self, action: #selector(HymnDetailViewController.Seek), for: .allEvents)
        //progressBar.autoresizingMask = .flexibleWidth
        //progressBar.sizeToFit()
        
        

        //print("PLAYER ITEM At view Did Load : -- \(playerItem)")
        ToolBar.tintColor = GlobalConstants.kColor_DarkColor
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(HymnDetailViewController.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(HymnDetailViewController.playButtonTapped))
        saveButton = UIBarButtonItem(image: UIImage(named: "download"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(HymnDetailViewController.saveFile))
        deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(HymnDetailViewController.deleteFile))
        
        let flexible = UIBarButtonItem(customView: progressBar)
        progressBarLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        progressBarLabel.adjustsFontSizeToFitWidth = true
        progressBarLabel.text = "00.00"
        let sliderLabel = UIBarButtonItem(customView: progressBarLabel)
        
        
        progressBar.minimumValue = 0
        
        //*******
        //*** check to see if there is a hymn playing
        //*******
        if checkPlayerRunning(audioString: "\(hymnAudioURL!)") == false {

            playerItem = AVPlayerItem(url: hymnAudioURL)
            //self.alhanPlayer = AVPlayer(playerItem: playerItem)
            AlhanPlayer.sharedInstance.player = AVPlayer(playerItem: playerItem)
            //AlhanPlayer.sharedInstance.player.replaceCurrentItem(with: playerItem)
            
            
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.insert(playButton, at: 0) // change index to wherever you'd like the button
        arrayOfButtons.insert(flexible, at: 1)
        arrayOfButtons.insert(sliderLabel, at: 2)
        // check if file is local
        if FileManager.default.fileExists(atPath: destinationUrl.path){
            arrayOfButtons.insert(deleteButton, at: 3)
        }else {
            arrayOfButtons.insert(saveButton, at: 3)
        }
        self.ToolBar.setItems(arrayOfButtons, animated: false)
       
        } else //*** if it is playing the hymn *****
        {
        
            arrayOfButtons = self.ToolBar.items!
            arrayOfButtons.insert(pauseButton, at: 0) // change index to wherever you'd like the button
            arrayOfButtons.insert(flexible, at: 1)
            arrayOfButtons.insert(sliderLabel, at: 2)
            // check if file is local
            if FileManager.default.fileExists(atPath: destinationUrl.path){
                arrayOfButtons.insert(deleteButton, at: 3)
            }else {
                arrayOfButtons.insert(saveButton, at: 3)
            }
            self.ToolBar.setItems(arrayOfButtons, animated: false)
            
            // get the bar to the playing position
            progressBar.maximumValue = Float((AlhanPlayer.sharedInstance.player.currentItem?.duration.seconds)!)
//            updater = CADisplayLink(target: self, selector: #selector(HymnDetailViewController.trackAudio))
//            updater.preferredFramesPerSecond = 60
//            updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
//        
        }
        
        // Media Info Center
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(HymnDetailViewController.pause))
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
        //updater!.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
        
        AlhanPlayer.sharedInstance.resetTimer()
        
    }
    
    func play() {

//            updater = CADisplayLink(target: self, selector: #selector(HymnDetailViewController.trackAudio))
//            updater.preferredFramesPerSecond = 60
//            updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
//
        let image:UIImage = UIImage(named: "artworkCross")!
        var albumArtWork: MPMediaItemArtwork!
        if #available(iOS 10.0, *) {
            albumArtWork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                return image
                
            })
        } else {
            // Fallback on earlier versions
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: " \((hymnDetail?[0].hymnDescription)!)",
            MPMediaItemPropertyArtwork: albumArtWork,
            MPMediaItemPropertyPlaybackDuration: NSNumber(value: (AlhanPlayer.sharedInstance.player.currentItem?.duration.seconds)!),
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1)
        ]
            AlhanPlayer.sharedInstance.play()
            // print("MAX VALUE: \(AlhanPlayer.sharedInstance.player.currentItem?.duration.seconds) --DONE")
            progressBar.maximumValue = Float((AlhanPlayer.sharedInstance.player.currentItem?.duration.seconds)!)
        
        
         }
    
    
    func pause() {

            AlhanPlayer.sharedInstance.player.volume = 1.0
            AlhanPlayer.sharedInstance.player.pause()
    }
    

    
    func playButtonTapped() {
        //print ("Here is the fileIsLocal variable: \(fileIsLocal)")
        //print ("Here is the Reachability: \(Reachability.isConnectedToNetwork())")
        
        if (!Reachability.isConnectedToNetwork()) && fileIsLocal == false{
            
             showAlertButton()
           
        
        }else
        {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(pauseButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        play()
        //print("%%% from PLAY \(AlhanPlayer.sharedInstance.player.rate)")
        }
         
        
    }
    
    func pauseButtonTapped() {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(playButton, at: 0)
        
        pause()
       
        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }

    func checkPlayerRunning(audioString: String) -> Bool{
        //print ("@@@ player rate \(AlhanPlayer.sharedInstance.player.rate)")
        //print ("$$$ here is the current session mode \(AVAudioSession.sharedInstance().mode)")
        //print ("$$$ here is the current session desc \(AVAudioSession.sharedInstance().description)$$$$$")
        var isRunning = false
        
        // Pause playlist if running
        if (AlhanPlayer.sharedInstance.queuePlayer.rate == 1.0 ) {
            print("### PlayList player is on")
            AlhanPlayer.sharedInstance.queuePlayer.pause()
        }
        
        // Check if runnning the same hymn
        if (AlhanPlayer.sharedInstance.player.rate == 1.0 ) {
        
            //print("### player is on")
            //print("\(AlhanPlayer.sharedInstance.player.currentItem?.description) -- END")
            //print("Audio String \(audioString.description) - DONE")
            
            //*** check if playing the same hymn

            if AlhanPlayer.sharedInstance.player.currentItem?.description.range(of: audioString) != nil {
                print ("++ Playing the same hymn, then let's get to where it is")
                //print ("+++ Here is where the hymn is \(AlhanPlayer.sharedInstance.player.currentTime().seconds)")
                isRunning = true
                progressBar.value = Float((AlhanPlayer.sharedInstance.player.currentTime().seconds))
            } else
            {
                AlhanPlayer.sharedInstance.player.pause()
            }
        }
        return isRunning
    }
    
    // MARK: tracking audio
    func trackAudio() {

        progressBar.value = Float((AlhanPlayer.sharedInstance.player.currentTime().seconds))
        //progressBarLabel.text = NSString(format: "%04.2f", progressBar.value) as String

        let minutes = Int(floor(progressBar.value / 60))
        let seconds = Int(round(progressBar.value.truncatingRemainder(dividingBy: 60)))
        let timeString = NSString(format: "%02d:%02d", minutes, seconds)
        //print("****** ProgressBar VALUE: \(timeString) ***")
        progressBarLabel.text = "\(timeString)"
        
    }
    
    func Seek(_ sender: UISlider) {
        
        AlhanPlayer.sharedInstance.player.pause()
        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(playButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
        AlhanPlayer.sharedInstance.player.seek(to: CMTimeMake(( Int64(progressBar.value)), 1) )
        //progressBarLabel.text = NSString(format: "%04.2f", progressBar.value) as String
        let minutes = Int(floor(progressBar.value / 60))
        let seconds = Int(round(progressBar.value.truncatingRemainder(dividingBy: 60)))
        let timeString = NSString(format: "%02d:%02d", minutes, seconds)
        //print("****** ProgressBar VALUE: \(timeString) ***")
        progressBarLabel.text = "\(timeString)"
        //alhanPlayer.play()
        play()
        
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(pauseButton, at: 0)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
    }
    
    

    
    // MARK: file handling
    
    func saveFile(){
        if let audioUrl = URL(string:  (hymnDetail?[0].hymnAudio)!) {
            
            // then lets create your document folder url
            // * defined as a Constant let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // create directory if it doesn't exist
               // print("@@@@@@@@ localDir \(localDir)")
            let localPath = documentsDirectoryURL.appendingPathComponent(localDir)
               // print("@@@@@@@@@ localPath\(localPath)")
                    do {
                        try FileManager.default.createDirectory(at: localPath, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                         NSLog("Unable to create directory \(error.debugDescription)")
                                }
            
            // lets create your destination file url
            let destinationUrl = localPath.appendingPathComponent(audioUrl.lastPathComponent)
            print(destinationUrl)

            
            // to check if it exists before downloading it
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("The file already exists at path")
                
                // if the file doesn't exist
            } else {
                
                // you can use NSURLSession.sharedSession to download the data asynchronously
                URLSession.shared.downloadTask(with: audioUrl, completionHandler: { (location, response, error) -> Void in
                    guard let location = location, error == nil else { return }
                    do {
                        // after downloading your file you need to move it to your destination url
                        try FileManager.default.moveItem(at: location, to: destinationUrl)
                        // print("<<<<<<<<<<<< File moved to documents folder \(destinationUrl )")
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }).resume()
            }
        }
        
        // change the button to delete
        arrayOfButtons.remove(at: 3) // change index to correspond to where your button is
        arrayOfButtons.insert(deleteButton, at: 3)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }

   
    func deleteFile(){
        let audioUrl = URL(string:  (hymnDetail?[0].hymnAudio)!)
        let localPath = documentsDirectoryURL.appendingPathComponent(localDir)
        let destinationUrl = localPath.appendingPathComponent((audioUrl?.lastPathComponent)!)
        
        do {
            
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            // Delete file
            print("NUKING the file.........")
            try FileManager.default.removeItem(atPath:  destinationUrl.path)
        } else {
            print("File does not exist")
        }
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
        // change the button to save
        arrayOfButtons.remove(at: 3) // change index to correspond to where your button is
        arrayOfButtons.insert(saveButton, at: 3)
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
        
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
        
//        if (updater != nil) {
//
//            updater.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
//        }
        
    }
    
    // Interruption handler
    
    var interruptedOnPlayback = false
    
    internal func audioPlayerBeginInterruption(_ player: AVAudioPlayer){
        
        print(player.debugDescription)
        
        print("--- audioPlayerBeginInterruption")
        DispatchQueue.main.async(execute: {
            print("--- main queue")
            self.pauseButtonTapped()
        })
        print("audioPlayer.playing", player.isPlaying)
        interruptedOnPlayback = true
        
        if deActivateSession() {
            print("AVAudioSession is inactive")
        }
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        print("--- audioPlayerEndInterruption")
        guard
            AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume
                && interruptedOnPlayback
        else { return }
        if activateSession() {
            print("AVAudioSession is Active again")
            interruptedOnPlayback = false
        DispatchQueue.main.async(execute: {
            self.playButtonTapped() })
        }
       
    }
    
    func activateSession() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("AVAudioSession is inactive")
            return true
        } catch let error as NSError {
            print(error.localizedDescription)
            return false
        }
    }
    func deActivateSession() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("AVAudioSession is inactive")
            return true
        } catch let error as NSError {
            print(error.localizedDescription)
            return false
        }
    }
    
    func swipeLeft(recognizer : UISwipeGestureRecognizer) {
        self.performSegue(withIdentifier: "Hymn Detail to Playlist", sender: self)
    }
    
    
    // Info center
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    
    override func remoteControlReceived(with event: UIEvent?) { // *
        let rc = event!.subtype
        let p = AlhanPlayer.sharedInstance.player
        print("received remote control \(rc.rawValue)") // 101 = pause, 100 = play
        switch rc {
        case .remoteControlTogglePlayPause:
            if p.rate == 1 { p.pause() } else { p.play() }
        case .remoteControlPlay:
            p.play()
        case .remoteControlPause:
            p.pause()
        default:break
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            switch identifier
            {
            case "PlayList":
                print ("I'm going to add hymn to selected playlist")
                let playlistVC = segue.destination as! PlayListVC
                var hymnArrays: [PlayHymns]!
                
                
                let hymnArray = PlayHymns(HymnName: hymnDetail?[0].hymnName, HymnID: hymnDetail?[0].hymnID, HymnURL: hymnDetail?[0].hymnAudio)
                                            if hymnArrays == nil {
                                                hymnArrays = [PlayHymns]()
                                            }
                hymnArrays.append(hymnArray)
                
                
                playlistVC.plHymnsArray = hymnArrays
                
                playlistInstructions = true
                
                print ("Going into playlist I have: \(hymnArrays.count)")
                
                
            default:
                break
                
                
                
                
            }
        }
    }
    
    
    
}
