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
    var shuffleButton = UIBarButtonItem()
    var samePlaylist: Bool = false
    let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    private let miniPlayer = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let nowPlayingLabel = UILabel()
    private let trackTitleLabel = UILabel()
    private let miniPlayPauseButton = UIButton(type: .system)
    private let miniNextButton = UIButton(type: .system)
    private let playbackProgress = UIProgressView(progressViewStyle: .default)
    private var playbackTimeObserver: Any?
    
    // Internet alert box
    @IBAction func showAlertButton() {
        let alert = UIAlertController(title: "No Internet Connection", message: "Only downloaded content will play offline. Please make sure you are connected to the internet to  be able to stream hymns.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarAppearance()
        configurePlaylistAppearance()
        plDetail.delegate = self
        plDetail.dataSource = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currentTrackDidChange),
            name: .alhanPlayerCurrentTrackDidChange,
            object: AlhanPlayer.sharedInstance
        )
        
        if (self.canBecomeFirstResponder){
            self.becomeFirstResponder()
        }
       
        
        playlistHymns = []

        if let array = PL_DBManager.shared.getPLHymns(playlist: self.title!) {
            
            playlistHymns = array

        }
        configureMiniPlayer()
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
        shuffleButton = UIBarButtonItem(image: UIImage(systemName: "shuffle"), style: .plain, target: self, action: #selector(shuffleButtonTapped))
        shuffleButton.accessibilityLabel = "Shuffle playlist"
        
        // Check Queue player status
        
        if checkPlayerRunning() == true {
            print("PLAYER IS RUNNING......")
            if samePlaylist == true {
                
                self.navigationItem.setRightBarButtonItems([shuffleButton], animated: true)
            } else {
                //AlhanPlayer.sharedInstance.queuePlayer.pause()
                self.navigationItem.setRightBarButtonItems([shuffleButton], animated: true)
            }
        }
            
        else {
            //AlhanPlayer.sharedInstance.queuePlayer.pause()
            print("PLAYER IS NOT RUNNING......")
            self.navigationItem.setRightBarButtonItems([shuffleButton], animated: true)
            }
        
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommandHandler(_:)))

        
        
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = GlobalConstants.kColor_DarkColor
        appearance.titleTextAttributes = [
            .foregroundColor: GlobalConstants.kColor_GoldColor,
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = GlobalConstants.kColor_GoldColor
    }

    private func configurePlaylistAppearance() {
        plDetail.rowHeight = 62
        plDetail.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        plDetail.backgroundColor = .systemGroupedBackground
        plDetail.contentInset.bottom = 108
        plDetail.verticalScrollIndicatorInsets.bottom = 108
    }

    private func configureMiniPlayer() {
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        miniPlayer.layer.cornerRadius = 22
        miniPlayer.layer.cornerCurve = .continuous
        miniPlayer.clipsToBounds = true
        miniPlayer.layer.borderWidth = 0.5
        miniPlayer.layer.borderColor = UIColor.separator.cgColor
        view.addSubview(miniPlayer)

        nowPlayingLabel.text = "NOW PLAYING"
        nowPlayingLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        nowPlayingLabel.adjustsFontForContentSizeCategory = true
        nowPlayingLabel.textColor = .secondaryLabel

        trackTitleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(
            for: UIFont(name: "COPT", size: 18) ?? UIFont.preferredFont(forTextStyle: .headline)
        )
        trackTitleLabel.adjustsFontForContentSizeCategory = true
        trackTitleLabel.textColor = GlobalConstants.kColor_DarkColor
        trackTitleLabel.lineBreakMode = .byTruncatingTail

        let labels = UIStackView(arrangedSubviews: [nowPlayingLabel, trackTitleLabel])
        labels.axis = .vertical
        labels.spacing = 2

        configureMiniPlayerButton(
            miniPlayPauseButton,
            symbolName: "play.fill",
            accessibilityLabel: "Play playlist",
            prominent: true,
            action: #selector(miniPlayPauseTapped)
        )
        configureMiniPlayerButton(
            miniNextButton,
            symbolName: "forward.end.fill",
            accessibilityLabel: "Next hymn",
            prominent: false,
            action: #selector(miniNextTapped)
        )

        let controls = UIStackView(arrangedSubviews: [labels, miniNextButton, miniPlayPauseButton])
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 10
        miniPlayer.contentView.addSubview(controls)

        playbackProgress.translatesAutoresizingMaskIntoConstraints = false
        playbackProgress.trackTintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.12)
        playbackProgress.progressTintColor = GlobalConstants.kColor_DarkColor
        miniPlayer.contentView.addSubview(playbackProgress)

        NSLayoutConstraint.activate([
            miniPlayer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            miniPlayer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            miniPlayer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            miniPlayer.heightAnchor.constraint(equalToConstant: 82),
            controls.leadingAnchor.constraint(equalTo: miniPlayer.contentView.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: miniPlayer.contentView.trailingAnchor, constant: -12),
            controls.topAnchor.constraint(equalTo: miniPlayer.contentView.topAnchor, constant: 10),
            playbackProgress.leadingAnchor.constraint(equalTo: miniPlayer.contentView.leadingAnchor, constant: 16),
            playbackProgress.trailingAnchor.constraint(equalTo: miniPlayer.contentView.trailingAnchor, constant: -16),
            playbackProgress.bottomAnchor.constraint(equalTo: miniPlayer.contentView.bottomAnchor, constant: -10),
            miniPlayPauseButton.widthAnchor.constraint(equalToConstant: 46),
            miniPlayPauseButton.heightAnchor.constraint(equalToConstant: 46),
            miniNextButton.widthAnchor.constraint(equalToConstant: 38),
            miniNextButton.heightAnchor.constraint(equalToConstant: 38)
        ])

        startMiniPlayerUpdates()
        updateMiniPlayer()
    }

    private func startMiniPlayerUpdates() {
        guard playbackTimeObserver == nil else { return }
        playbackTimeObserver = AlhanPlayer.sharedInstance.queuePlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateMiniPlayer() }
        }
    }

    private func stopMiniPlayerUpdates() {
        guard let playbackTimeObserver else { return }
        AlhanPlayer.sharedInstance.queuePlayer.removeTimeObserver(playbackTimeObserver)
        self.playbackTimeObserver = nil
    }

    private func configureMiniPlayerButton(
        _ button: UIButton,
        symbolName: String,
        accessibilityLabel: String,
        prominent: Bool,
        action: Selector
    ) {
        var configuration = prominent
            ? UIButton.Configuration.filled()
            : UIButton.Configuration.tinted()
        configuration.image = UIImage(systemName: symbolName)
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = prominent ? .white : GlobalConstants.kColor_DarkColor
        configuration.baseBackgroundColor = prominent
            ? GlobalConstants.kColor_DarkColor
            : GlobalConstants.kColor_GoldColor.withAlphaComponent(0.32)
        button.configuration = configuration
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func updateMiniPlayer() {
        let player = AlhanPlayer.sharedInstance
        trackTitleLabel.text = player.currentTrackTitle ?? "Choose a hymn"
        miniPlayPauseButton.isEnabled = !playlistHymns.isEmpty
        miniNextButton.isEnabled = player.queuePlayer.items().count > 1

        var configuration = miniPlayPauseButton.configuration
        configuration?.image = UIImage(systemName: player.isPlaying ? "pause.fill" : "play.fill")
        miniPlayPauseButton.configuration = configuration
        miniPlayPauseButton.accessibilityLabel = player.isPlaying ? "Pause" : "Play"

        let duration = player.duration
        playbackProgress.progress = duration > 0
            ? Float(player.currentTime / duration)
            : 0
    }

    @objc private func miniPlayPauseTapped() {
        let player = AlhanPlayer.sharedInstance
        if player.currentTrackURL == nil {
            playButtonTapped()
        } else {
            player.togglePlayback()
            updateMiniPlayer()
        }
    }

    @objc private func miniNextTapped() {
        nextButtonTapped()
        updateMiniPlayer()
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
            var content = cell.defaultContentConfiguration()
            content.text = playlistHymns[row].HymnName
            content.textProperties.font = UIFontMetrics(forTextStyle: .headline).scaledFont(
                for: UIFont(name: "COPT", size: 19) ?? UIFont.preferredFont(forTextStyle: .headline)
            )
            content.textProperties.color = GlobalConstants.kColor_DarkColor
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 10,
                leading: 20,
                bottom: 10,
                trailing: 12
            )
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            configurePlaybackAppearance(for: cell, at: indexPath)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        startPlayback(shuffled: false, startingAt: indexPath.row)
    }

    private func configurePlaybackAppearance(for cell: UITableViewCell, at indexPath: IndexPath) {
        let isCurrentTrack = isPlayingHymn(at: indexPath.row)
        cell.backgroundColor = isCurrentTrack
            ? GlobalConstants.kColor_GoldColor.withAlphaComponent(0.28)
            : .clear
        cell.accessibilityTraits = isCurrentTrack
            ? [.button, .selected]
            : [.button]

        if isCurrentTrack {
            let imageView = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))
            imageView.tintColor = GlobalConstants.kColor_DarkColor
            imageView.isAccessibilityElement = false
            cell.accessoryView = imageView
        } else {
            cell.accessoryView = nil
        }
    }

    private func isPlayingHymn(at row: Int) -> Bool {
        guard playlistHymns.indices.contains(row),
              let playlistURL = URL(string: playlistHymns[row].HymnURL),
              let currentURL = AlhanPlayer.sharedInstance.currentTrackURL else { return false }
        return playlistURL == currentURL
            || playlistURL.lastPathComponent == currentURL.lastPathComponent
    }

    @objc private func currentTrackDidChange() {
        updateMiniPlayer()
        plDetail.reloadData()
        guard let currentRow = playlistHymns.indices.first(where: { isPlayingHymn(at: $0) }) else { return }
        plDetail.scrollToRow(
            at: IndexPath(row: currentRow, section: 0),
            at: .none,
            animated: true
        )
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
        let row = hymnURLS.firstIndex(of: hymnURL)
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
        startPlayback(shuffled: false, startingAt: nil)
    }

    @objc private func shuffleButtonTapped() {
        startPlayback(shuffled: true, startingAt: nil)
    }

    private func startPlayback(shuffled: Bool, startingAt startIndex: Int?) {
        if playlistHymns.count > 0{
        /*if !(Reachability.isConnectedToNetwork()) && fileIsLocal == false{
            
            showAlertButton()
            
            
        }else
        {*/
        
//        if (AlhanPlayer.sharedInstance.queuePlayer.rate == 1.0 ) {
//            print("********* IT WAS PLAYING ********")
//            AlhanPlayer.sharedInstance.queuePlayer.pause()
//        }
        
        
       
        self.navigationItem.setRightBarButtonItems([shuffleButton], animated: true)
        
       
            // Pause individual hymn if running
            if (AlhanPlayer.sharedInstance.player.rate == 1.0 ) {
                print("### Hymn player was on")
                AlhanPlayer.sharedInstance.player.pause()
            }

        
        var playableTracks = [AlhanPlayer.Track]()
        let hymnsToPlay: [PlaylistHymns]
        if let startIndex, playlistHymns.indices.contains(startIndex) {
            hymnsToPlay = Array(playlistHymns[startIndex...])
        } else {
            hymnsToPlay = playlistHymns
        }
        for hymnURL in hymnsToPlay {
            
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
            
            
            playableTracks.append(
                .init(
                    url: hymnAudioURL!,
                    title: hymnURL.HymnName ?? "iAlhan",
                    albumTitle: title
                )
            )
            print("****** HYMN URL TO PLAY: \(String(describing: hymnAudioURL))")
            
            //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
            }
        }
            
        if !playableTracks.isEmpty {
            let queuedTracks = shuffled ? playableTracks.shuffled() : playableTracks
            AlhanPlayer.sharedInstance.loadQueue(queuedTracks, autoplay: true)
        }
        
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
    
    @objc private func pauseCommandHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        pauseButtonTapped()
        return .success
    }

    @objc func pauseButtonTapped() {
            self.navigationItem.setRightBarButtonItems([shuffleButton], animated: true)
        
           AlhanPlayer.sharedInstance.pauseQueue()
            
            //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
        
    }
    
    @objc func nextButtonTapped() {
        
        AlhanPlayer.sharedInstance.nextHymnInQueue()
        
        //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
        
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startMiniPlayerUpdates()
        updateMiniPlayer()
        self.becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMiniPlayerUpdates()
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
