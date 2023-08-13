//
//  PlaylistDetailVC.swift
//  iAlhan
//
//  Created by ARSANI SIDAROUS on 10/30/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

struct PlaylistHymns{
    
    var HymnName: String!
    var HymnID: Int!
    var HymnURL: String!
}

//@available(iOS 10.0, *)
class PlaylistDetailVC:  UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var PlayPauseButton: UIBarButtonItem!
    @IBOutlet var plDetail: UITableView!
    
    var playlistHymns:[PlaylistHymns]!
    
    var hymnURLS = [URL]()
    
    var pauseButton = UIBarButtonItem()
    var playButton = UIBarButtonItem()
    var nextButton = UIBarButtonItem()
    var samePlaylist: Bool = false
    let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Internet alert box
    @IBAction func showAlertButton() {
        let alert = UIAlertController(title: "No Internet Connection", message: "Only downloaded content will play offline. Please make sure you are connected to the internet to  be able to stream hymns.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        plDetail.delegate = self
        plDetail.dataSource = self
        
        if (self.canBecomeFirstResponder){
            self.becomeFirstResponder()
        }
       
        
        playlistHymns = []

        if let array = PL_DBManager.shared.getPLHymns(playlist: self.title!) {
            
            playlistHymns = array

        }
            //print("\(playlistHymns.count)")
        // Do any additional setup after loading the view.
        
        for playlistHymn in playlistHymns {
            
            hymnURLS.append(URL(string: playlistHymn.HymnURL)!)
        }
//
        print("HYMN URLS: \(hymnURLS)")
        
        // handles audio when device is muted
        do {
            
             if #available(iOS 10.0, *) {
                 try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)) , options: AVAudioSession.CategoryOptions.allowAirPlay)
             }else{
            
                 try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)) )
            }
            
                
            try AVAudioSession.sharedInstance().setActive(true)
            
        }
        catch {
            print(error)
        }
        
        // Define buttons
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.pause, target: self, action: #selector(PlaylistDetailVC.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play, target: self, action: #selector(PlaylistDetailVC.playButtonTapped))
        nextButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fastForward, target: self, action: #selector(PlaylistDetailVC.nextButtonTapped))
        
        // Check Queue player status
        
        if checkPlayerRunning() == true {
            print("PLAYER IS RUNNING......")
            if samePlaylist == true {
                
                self.navigationItem.setRightBarButtonItems([pauseButton, nextButton], animated: true)
            } else {
                //AlhanPlayer.sharedInstance.queuePlayer.pause()
                self.navigationItem.setRightBarButton(playButton, animated: true)
            }
        }
            
        else {
            //AlhanPlayer.sharedInstance.queuePlayer.pause()
            print("PLAYER IS NOT RUNNING......")
            self.navigationItem.setRightBarButton(playButton, animated: true)
            }
        
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(PlaylistDetailVC.pauseButtonTapped))

        
        
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("No of rows: \(playlistHymns.count)!")
        var noOfRows: Int = 0
        
        if (playlistHymns.count) > 0{
            noOfRows = (playlistHymns.count)
        }
        
        return noOfRows
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "hymnCell", for: indexPath) 
        
        let row = indexPath.row
        
        //print("just outside")
        if ((playlistHymns.count) > 0)
        {
            //print("Got in")
            cell.textLabel?.text = playlistHymns[row].HymnName
        }
        
        
        
        return cell
    }
    

//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
//            // delete item at indexPath
//            let row = indexPath.row
//            PL_DBManager.shared.removeHymnsFromPL(hymnID: self.playlistHymns[row].HymnID)
//            self.playlistHymns.remove(at: row)
//            tableView.deleteRows(at: [indexPath], with: .fade)
//        }
//        
//        
//        return [delete]
//    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        
        if editingStyle == .delete {
            // Delete the row from the data source
            print("I'm about to delete the following: \(String(describing: self.playlistHymns[row].HymnID))")
            PL_DBManager.shared.removeHymnsFromPL(hymnID: self.playlistHymns[row].HymnID)
            self.playlistHymns.remove(at: row)
            tableView.deleteRows (at: [indexPath], with: .fade)

            //tableView.
            //self.tableView.reloadData()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func highlightRow (hymnURL: URL){
        print ("Highlight hymn url \(hymnURL)")
        let row = hymnURLS.index(of: hymnURL)
        print("ROW: \(String(describing: row))")
       // self.plDetail.cellForRow(at: IndexPath(row: row!, section: 0))?.contentView.backgroundColor = UIColor.gray
    
    
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Audio controls
//    @IBAction func Play(_ sender: AnyObject) {
//        playButtonTapped()
//        
//        
//    }
    
    func checkPlayerRunning() -> Bool{
        print ("@@@ player rate \(AlhanPlayer.sharedInstance.player.rate)")
        print ("@@@ QUEUE player rate \(AlhanPlayer.sharedInstance.queuePlayer.rate)")
        //print ("$$$ here is the current session mode \(AVAudioSession.sharedInstance().mode)")
        //print ("$$$ here is the current session desc \(AVAudioSession.sharedInstance().description)$$$$$")
        var isRunning = false
        
        
        // Pause player if running
        if (AlhanPlayer.sharedInstance.queuePlayer.rate == 1.0 ) {
            // check to see if the hymn is part of the playlist
//            
            for hymnURL in playlistHymns{
                //print("Now playing : \(AlhanPlayer.sharedInstance.player.currentItem?.description)")
                print("DESCRIPTION: \(String(describing: AlhanPlayer.sharedInstance.queuePlayer.currentItem?.description))")
                print("\n")
                print("HymnURL: \(String(describing: hymnURL.HymnURL))")
                print("===========================")
                if AlhanPlayer.sharedInstance.queuePlayer.currentItem?.description.range(of: String(hymnURL.HymnURL)) != nil {
                    print ("++ Playing the same hymn, then we're in the same playlist")
                    //print ("+++ Here is where the hymn is \(AlhanPlayer.sharedInstance.player.currentTime().seconds)")
                    samePlaylist = true
                    break
                    }
            }
            
            if samePlaylist == false{
                print ("++ Not in the same playlist")
                AlhanPlayer.sharedInstance.pauseQueue()
                AlhanPlayer.sharedInstance.queuePlayer.removeAllItems()
            }

//        //AlhanPlayer.sharedInstance.queuePlayer.pause()
            isRunning = true
        }
        
        
       
        
       
        return isRunning
    }
    

    
    @objc func playButtonTapped() {
        if playlistHymns.count > 0{
        /*if !(Reachability.isConnectedToNetwork()) && fileIsLocal == false{
            
            showAlertButton()
            
            
        }else
        {*/
        
//        if (AlhanPlayer.sharedInstance.queuePlayer.rate == 1.0 ) {
//            print("********* IT WAS PLAYING ********")
//            AlhanPlayer.sharedInstance.queuePlayer.pause()
//        }
        
        
       
        self.navigationItem.setRightBarButtonItems([pauseButton, nextButton], animated: true)
        
       
            // Pause individual hymn if running
            if (AlhanPlayer.sharedInstance.player.rate == 1.0 ) {
                print("### Hymn player was on")
                AlhanPlayer.sharedInstance.player.pause()
            }

        
        for hymnURL in playlistHymns{
            
            //print("HYMN URL TO PLAY: \(hymnURL)")
            var fileIsLocal = false
            // check to see if the file is local and thus play from local
            let localDir = getDirectory(url: String(describing: hymnURL.HymnURL))
            let localPath = documentsDirectoryURL.appendingPathComponent(localDir)
            var hymnAudioURL = URL(string: (hymnURL.HymnURL))
            let destinationUrl = localPath.appendingPathComponent((hymnAudioURL?.lastPathComponent)!)
            
            if FileManager.default.fileExists(atPath: destinationUrl.path){
                hymnAudioURL = destinationUrl
                fileIsLocal = true
                // print("!!!!!! playing the local file - TOP")
            }
            
            
            if !(Reachability.isConnectedToNetwork()) && fileIsLocal == false{
                
                showAlertButton()
                
                
            }else {
            
            
            //AlhanPlayer.sharedInstance.playQueue(playerURL: URL(string: hymnURL.HymnURL)!)
            AlhanPlayer.sharedInstance.playQueue(playerURL: hymnAudioURL!)
            print("****** HYMN URL TO PLAY: \(String(describing: hymnAudioURL))")
            
            //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
            }
        }
            
            let image:UIImage = UIImage(named: "artworkCross")!
            
            var albumArtWork:MPMediaItemArtwork!
            
            if #available(iOS 10.0, *) {
                albumArtWork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                    return image  })
            }else{
                albumArtWork = MPMediaItemArtwork.init(image: image)

            }
    
        AlhanPlayer.sharedInstance.queuePlayer.play()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: " \((playlistHymns[0].HymnName)!)",
            MPMediaItemPropertyArtwork: albumArtWork,
            MPMediaItemPropertyPlaybackDuration: NSNumber(value: (AlhanPlayer.sharedInstance.queuePlayer.currentItem?.duration.seconds)!),
            MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1)
        ]
        print("TEST \(String(describing: AlhanPlayer.sharedInstance.queuePlayer.currentItem?.duration.seconds))")
        
        //let test = AlhanPlayer.sharedInstance.queuePlayer.currentItem
        //print("TEST :\(test)")
        //play()
        //print("%%% from PLAY \(AlhanPlayer.sharedInstance.player.rate)")
        
        }
        else
        {
            let alert = UIAlertController(title: "No Hymns in Playlist", message: "Please add hymns to current playlist before pressing play.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func pauseButtonTapped() {
            self.navigationItem.setRightBarButtonItems([playButton], animated: true)
        
           AlhanPlayer.sharedInstance.pauseQueue()
            
            //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
        
    }
    
    @objc func nextButtonTapped() {
        
        AlhanPlayer.sharedInstance.nextHymnInQueue()
        
        //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
        
    }
    
    
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
        let p = AlhanPlayer.sharedInstance.queuePlayer
        print("received remote control \(rc.rawValue)") // 101 = pause, 100 = play
        switch rc {
        case .remoteControlTogglePlayPause:
            if p.rate == 1 { AlhanPlayer.sharedInstance.pauseQueue() } else { p.play() }
        case .remoteControlPlay:
            p.play()
        case .remoteControlPause:
            AlhanPlayer.sharedInstance.pauseQueue()
        case .remoteControlNextTrack:
            AlhanPlayer.sharedInstance.nextHymnInQueue()
        default:break
        }
    }
    


}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
