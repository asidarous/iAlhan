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

class HymnDetailViewController: UIViewController, UITextViewDelegate{

    @IBOutlet var ToolBar: UIToolbar!
    @IBOutlet var HymnTextEnglish: UITextView!
    @IBOutlet var HymnTextCoptic: UITextView!
    
    

//    var backgroundSession: Foundation.URLSession!
//    var downloadTask: URLSessionDownloadTask!
    
    var ProgressBar: UISlider!

    var pauseButton = UIBarButtonItem()
    var playButton = UIBarButtonItem()
    var saveButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    
    
    var arrayOfButtons = [UIBarButtonItem]()

    var hymnDetail: [EventHymns]?
    
    var alhanPlayer = AVPlayer()
    var playerItem: AVPlayerItem!
    var hymnAudioURL: URL!
    var error:NSError?
    
    var asset:AVAsset?
    
    var updater : CADisplayLink! = nil
    
    var localDir: String!
    
    let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

 //   var fileName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // file download handling
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
            print("!!!!!! playing the local file - TOP")
        }
        
        // check to see if there is a hymn playing
        //checkPlayerRunning(audioString: "\(hymnAudioURL)")
        
        //new progress bar
        ProgressBar = UISlider(frame:CGRect(x: 10, y: 100, width: 280, height: 20))
        ProgressBar.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        ProgressBar.thumbTintColor = GlobalConstants.kColor_DarkColor
        ProgressBar.isUserInteractionEnabled = true
        
        ProgressBar.addTarget(self, action: #selector(HymnDetailViewController.Seek), for: .allEvents)
        ProgressBar.sizeToFit()

        
        playerItem = AVPlayerItem(url: hymnAudioURL)
        self.alhanPlayer = AVPlayer(playerItem: playerItem)
        
        //print("PLAYER ITEM At view Did Load : -- \(playerItem)")
        ToolBar.tintColor = GlobalConstants.kColor_DarkColor
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(HymnDetailViewController.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(HymnDetailViewController.playButtonTapped))
        saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(HymnDetailViewController.saveFile))
        deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(HymnDetailViewController.deleteFile))
       
        let flexible = UIBarButtonItem(customView: ProgressBar)
        
        
        // temp
       // let audioUrl = URL(string:  (hymnDetail?[0].hymnAudio)!)
        

        
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.insert(playButton, at: 0) // change index to wherever you'd like the button
        arrayOfButtons.insert(flexible, at: 1)
        // check if file is local
        if FileManager.default.fileExists(atPath: destinationUrl.path){
            arrayOfButtons.insert(deleteButton, at: 2)
        }else {
            arrayOfButtons.insert(saveButton, at: 2)
        }
        self.ToolBar.setItems(arrayOfButtons, animated: false)
        
      
        
        
        ProgressBar.minimumValue = 0
        //ProgressBar.maximumValue = 100
            //Float((alhanPlayer.currentItem?.duration.seconds)!)
        
        // **** TODO - check for file if local then set button to delete
        
        
        
        
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
            print("DESCRIPTION from inside the player \(alhanPlayer.currentItem?.description)")
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
        print("%%% from PLAY \(alhanPlayer.rate)")

        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }
    
    func pauseButtonTapped() {
        arrayOfButtons = self.ToolBar.items!
        arrayOfButtons.remove(at: 0) // change index to correspond to where your button is
        arrayOfButtons.insert(playButton, at: 0)
        
        pause()
       
        self.ToolBar.setItems(arrayOfButtons, animated: false)
    }

    func checkPlayerRunning(audioString: String){
        print ("$$$ here is the player rate \(self.alhanPlayer.rate)")
        if self.alhanPlayer.rate == 1.0 {
        
            print("### player is on")
            // check if playing the same hymn
            if alhanPlayer.currentItem?.description.range(of: audioString) != nil {
                print ("++ Playing the same hymn, then let's get to where it is")
                ProgressBar.value = Float((alhanPlayer.currentTime().seconds))
            } else
            {
                alhanPlayer.pause()
                updater.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
            }
        }
    
    }
    
    // MARK: tracking audio
    func trackAudio() {
        //let normalizedTime = Float((alhanPlayer.currentTime().seconds) * 100 / (alhanPlayer.currentItem?.duration.seconds)!)

        ProgressBar.value = Float((alhanPlayer.currentTime().seconds))
        //normalizedTime
        
    }
    
    func Seek(_ sender: UISlider) {
        
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
        arrayOfButtons.remove(at: 2) // change index to correspond to where your button is
        arrayOfButtons.insert(deleteButton, at: 2)
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
        arrayOfButtons.remove(at: 2) // change index to correspond to where your button is
        arrayOfButtons.insert(saveButton, at: 2)
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
