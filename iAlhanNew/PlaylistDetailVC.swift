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
    
    var RowID: Int64
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
    private let miniPreviousButton = UIButton(type: .system)
    private let miniPlayPauseButton = UIButton(type: .system)
    private let miniNextButton = UIButton(type: .system)
    private let elapsedTimeLabel = UILabel()
    private let playbackProgress = UISlider()
    private let durationTimeLabel = UILabel()
    private var playbackTimeObserver: Any?
    private var isScrubbing = false

    private let headerView = UIView()
    private let headerTitleLabel = UILabel()
    private let shuffleHeaderButton = UIButton(type: .system)
    private let editHeaderButton = UIButton(type: .system)
    
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
        configureHeader()
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
        
        // Configure and activate the audio session away from the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let audioSession = AVAudioSession.sharedInstance()

                try audioSession.setCategory(.playback, options: .allowAirPlay)

                try audioSession.setActive(true)
            } catch {
                print(error)
            }
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
                
                self.navigationItem.setRightBarButtonItems([editButtonItem, shuffleButton], animated: true)
            } else {
                //AlhanPlayer.sharedInstance.queuePlayer.pause()
                self.navigationItem.setRightBarButtonItems([editButtonItem, shuffleButton], animated: true)
            }
        }
            
        else {
            //AlhanPlayer.sharedInstance.queuePlayer.pause()
            print("PLAYER IS NOT RUNNING......")
            self.navigationItem.setRightBarButtonItems([editButtonItem, shuffleButton], animated: true)
            }
        
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommandHandler(_:)))

        
        
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        plDetail.setEditing(editing, animated: animated)
        plDetail.reloadData()
        AppAppearance.configureRoundNavigationButton(
            editHeaderButton,
            systemImageName: editing ? "checkmark" : "pencil",
            accessibilityLabel: editing ? "Done editing playlist" : "Edit playlist"
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // Keep the system edge-swipe navigation available while this screen's
        // navigation bar is hidden.
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetWidth = plDetail.bounds.width
        if headerView.frame.width != targetWidth {
            headerView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: 60)
            plDetail.tableHeaderView = headerView
        }
    }

    private func configureHeader() {
        headerView.backgroundColor = GlobalConstants.kColor_DarkColor

        headerTitleLabel.text = title
        headerTitleLabel.textColor = GlobalConstants.kColor_GoldColor
        // Matches the compact, centered inline title used by Season Detail and Hymn
        // Detail (this screen draws its own header instead of a real UINavigationBar,
        // so it needs to match that style explicitly rather than inheriting it).
        headerTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        headerTitleLabel.adjustsFontForContentSizeCategory = true
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.lineBreakMode = .byTruncatingTail
        headerTitleLabel.accessibilityTraits = .header
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        AppAppearance.configureRoundNavigationButton(
            editHeaderButton,
            systemImageName: "pencil",
            accessibilityLabel: "Edit playlist"
        )
        editHeaderButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        editHeaderButton.translatesAutoresizingMaskIntoConstraints = false

        AppAppearance.configureRoundNavigationButton(
            shuffleHeaderButton,
            systemImageName: "shuffle",
            accessibilityLabel: "Shuffle playlist"
        )
        shuffleHeaderButton.addTarget(self, action: #selector(shuffleButtonTapped), for: .touchUpInside)
        shuffleHeaderButton.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(headerTitleLabel)
        headerView.addSubview(shuffleHeaderButton)
        headerView.addSubview(editHeaderButton)

        // Centered like a real navigation bar's inline title, but allowed to yield that
        // centering (lower priority) rather than collide with the leading edge or the
        // shuffle/edit buttons if the playlist name ever needs more room than that leaves.
        let centeredTitle = headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor)
        centeredTitle.priority = .defaultHigh

        NSLayoutConstraint.activate([
            centeredTitle,
            headerTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 20),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: shuffleHeaderButton.leadingAnchor, constant: -12),

            editHeaderButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            editHeaderButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            editHeaderButton.widthAnchor.constraint(equalToConstant: 44),
            editHeaderButton.heightAnchor.constraint(equalToConstant: 44),

            shuffleHeaderButton.trailingAnchor.constraint(equalTo: editHeaderButton.leadingAnchor, constant: -8),
            shuffleHeaderButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            shuffleHeaderButton.widthAnchor.constraint(equalToConstant: 44),
            shuffleHeaderButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        headerView.frame = CGRect(x: 0, y: 0, width: plDetail.bounds.width, height: 60)
        plDetail.tableHeaderView = headerView
    }

    @objc private func editButtonTapped() {
        setEditing(!isEditing, animated: true)
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
        plDetail.separatorStyle = .singleLine
        plDetail.separatorColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.22)
        plDetail.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        AppAppearance.configureCreamBackground(for: view)
        AppAppearance.configureCreamBackground(for: plDetail)
        plDetail.contentInset.bottom = 128
        plDetail.verticalScrollIndicatorInsets.bottom = 128
    }

    private func configureMiniPlayer() {
        miniPlayer.effect = nil
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        miniPlayer.backgroundColor = AppAppearance.cellCreamColor
        miniPlayer.contentView.backgroundColor = AppAppearance.playerTintColor
        miniPlayer.layer.cornerRadius = 22
        miniPlayer.layer.cornerCurve = .continuous
        miniPlayer.clipsToBounds = true
        miniPlayer.layer.borderWidth = 0.8
        miniPlayer.layer.borderColor = AppAppearance.playerBorderColor.cgColor
        view.addSubview(miniPlayer)

        nowPlayingLabel.text = "NOW PLAYING"
        let nowPlayingBaseFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
        nowPlayingLabel.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(
            for: nowPlayingBaseFont
        )
        nowPlayingLabel.adjustsFontForContentSizeCategory = true
        nowPlayingLabel.textColor = GlobalConstants.kColor_DarkColor

        trackTitleLabel.font = AppAppearance.copticFont(ofSize: 18, relativeTo: .headline)
        trackTitleLabel.adjustsFontForContentSizeCategory = true
        trackTitleLabel.textColor = GlobalConstants.kColor_DarkColor
        trackTitleLabel.lineBreakMode = .byTruncatingTail

        let labels = UIStackView(arrangedSubviews: [nowPlayingLabel, trackTitleLabel])
        labels.axis = .vertical
        labels.spacing = 2

        configureMiniPlayerButton(
            miniPreviousButton,
            symbolName: "backward.end.fill",
            accessibilityLabel: "Previous hymn",
            prominent: false,
            action: #selector(miniPreviousTapped)
        )
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

        let controls = UIStackView(arrangedSubviews: [labels, miniPreviousButton, miniPlayPauseButton, miniNextButton])
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 10
        miniPlayer.contentView.addSubview(controls)

        playbackProgress.translatesAutoresizingMaskIntoConstraints = false
        playbackProgress.minimumValue = 0
        playbackProgress.maximumValue = 1
        playbackProgress.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        playbackProgress.maximumTrackTintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.12)
        playbackProgress.thumbTintColor = GlobalConstants.kColor_DarkColor
        playbackProgress.accessibilityLabel = "Playback position"
        playbackProgress.accessibilityHint = "Swipe up or down to seek through the hymn"
        playbackProgress.addTarget(self, action: #selector(scrubbingDidBegin), for: .touchDown)
        playbackProgress.addTarget(self, action: #selector(scrubberValueChanged), for: .valueChanged)
        playbackProgress.addTarget(
            self,
            action: #selector(scrubbingDidEnd),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        configureTimeLabel(elapsedTimeLabel, alignment: .right)
        configureTimeLabel(durationTimeLabel, alignment: .left)
        let timeline = UIStackView(arrangedSubviews: [elapsedTimeLabel, playbackProgress, durationTimeLabel])
        timeline.translatesAutoresizingMaskIntoConstraints = false
        timeline.axis = .horizontal
        timeline.alignment = .center
        timeline.spacing = 8
        miniPlayer.contentView.addSubview(timeline)

        NSLayoutConstraint.activate([
            miniPlayer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            miniPlayer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            miniPlayer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            miniPlayer.heightAnchor.constraint(equalToConstant: 104),
            controls.leadingAnchor.constraint(equalTo: miniPlayer.contentView.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: miniPlayer.contentView.trailingAnchor, constant: -12),
            controls.topAnchor.constraint(equalTo: miniPlayer.contentView.topAnchor, constant: 10),
            timeline.leadingAnchor.constraint(equalTo: miniPlayer.contentView.leadingAnchor, constant: 12),
            timeline.trailingAnchor.constraint(equalTo: miniPlayer.contentView.trailingAnchor, constant: -12),
            timeline.bottomAnchor.constraint(equalTo: miniPlayer.contentView.bottomAnchor, constant: -10),
            elapsedTimeLabel.widthAnchor.constraint(equalToConstant: 42),
            durationTimeLabel.widthAnchor.constraint(equalToConstant: 42),
            miniPreviousButton.widthAnchor.constraint(equalToConstant: 38),
            miniPreviousButton.heightAnchor.constraint(equalToConstant: 38),
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

    private func configureTimeLabel(_ label: UILabel, alignment: NSTextAlignment) {
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.text = "0:00"
        label.textAlignment = alignment
        label.textColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.78)
        label.isAccessibilityElement = false
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let totalSeconds = Int(time.rounded(.down))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    private func updateMiniPlayer() {
        let player = AlhanPlayer.sharedInstance
        if player.hasCurrentItem {
            trackTitleLabel.text = player.currentTrackTitle ?? "Now Playing"
            nowPlayingLabel.isHidden = false
        } else {
            trackTitleLabel.text = nil
            nowPlayingLabel.isHidden = true
        }
        miniPlayPauseButton.isEnabled = !playlistHymns.isEmpty
        miniPreviousButton.isEnabled = player.canGoBack
        miniNextButton.isEnabled = player.canAdvance

        var configuration = miniPlayPauseButton.configuration
        configuration?.image = UIImage(systemName: player.isPlaying ? "pause.fill" : "play.fill")
        miniPlayPauseButton.configuration = configuration
        miniPlayPauseButton.accessibilityLabel = player.isPlaying ? "Pause" : "Play"

        let duration = player.duration
        playbackProgress.isEnabled = duration > 0
        if !isScrubbing {
            playbackProgress.value = duration > 0
                ? Float(player.currentTime / duration)
                : 0
            elapsedTimeLabel.text = formattedTime(player.currentTime)
        }
        durationTimeLabel.text = formattedTime(duration)
        playbackProgress.accessibilityValue = "\(elapsedTimeLabel.text ?? "0:00") of \(durationTimeLabel.text ?? "0:00")"
    }

    @objc private func scrubbingDidBegin() {
        isScrubbing = true
    }

    @objc private func scrubberValueChanged() {
        let previewTime = Double(playbackProgress.value) * AlhanPlayer.sharedInstance.duration
        elapsedTimeLabel.text = formattedTime(previewTime)
        playbackProgress.accessibilityValue = "\(formattedTime(previewTime)) of \(formattedTime(AlhanPlayer.sharedInstance.duration))"
    }

    @objc private func scrubbingDidEnd() {
        seekToScrubberPosition()
        isScrubbing = false
    }

    private func seekToScrubberPosition() {
        let player = AlhanPlayer.sharedInstance
        guard player.duration > 0 else { return }
        player.seek(to: Double(playbackProgress.value) * player.duration)
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

    @objc private func miniPreviousTapped() {
        AlhanPlayer.sharedInstance.returnToPreviousItem()
        updateMiniPlayer()
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

    
    /// Playlist hymns are persisted as text, so legacy rows receive Ava Shenouda
    /// whenever they are displayed after an app update.
    private func applyAvaShenoudaFont(to content: inout UIListContentConfiguration) {
        let avaShenoudaFont = UIFont(name: "FreeSerifAvvaShenouda", size: 21)
            ?? AppAppearance.copticBaseFont(ofSize: 21)
        content.textProperties.font = ReadingPreferences.scaledFont(
            baseFont: avaShenoudaFont,
            relativeTo: .body,
            compatibleWith: traitCollection
        )
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
            applyAvaShenoudaFont(to: &content)
            content.textProperties.color = GlobalConstants.kColor_DarkColor

            if tableView.isEditing {
                content.secondaryText = "Drag to reorder"
                content.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .caption2)
                content.secondaryTextProperties.color = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.65)
            }

            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 10,
                leading: 20,
                bottom: 10,
                trailing: 12
            )
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            cell.showsReorderControl = true
            configurePlaybackAppearance(for: cell, at: indexPath)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        startPlayback(shuffled: false, startingAt: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard tableView.isEditing else { return }

        // UIKit installs its reorder control after configuring the cell, so tint the
        // visible trailing control on the next layout pass.
        DispatchQueue.main.async { [weak cell] in
            guard let cell else { return }
            self.tintTrailingReorderControl(in: cell, rootView: cell)
        }
    }

    private func tintTrailingReorderControl(in view: UIView, rootView cell: UITableViewCell) {
        let frameInCell = view.convert(view.bounds, to: cell)
        let isTrailingControl = frameInCell.midX > cell.bounds.width * 0.75

        if isTrailingControl {
            view.tintColor = GlobalConstants.kColor_DarkColor
            if let imageView = view as? UIImageView, let image = imageView.image {
                imageView.image = image.withRenderingMode(.alwaysTemplate)
            }
        }

        for subview in view.subviews {
            tintTrailingReorderControl(in: subview, rootView: cell)
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        let movedHymn = playlistHymns.remove(at: sourceIndexPath.row)
        playlistHymns.insert(movedHymn, at: destinationIndexPath.row)
        hymnURLS = playlistHymns.compactMap { URL(string: $0.HymnURL) }

        let orderedRowIDs = playlistHymns.map(\.RowID)
        PL_DBManager.shared.reorderHymns(orderedRowIDs: orderedRowIDs)

        // UIKit recreates every visible reorder control after the drop. Refresh the
        // table together so all burgundy handles and separators remain consistent.
        DispatchQueue.main.async { [weak tableView] in
            guard let tableView, tableView.isEditing else { return }
            UIView.performWithoutAnimation {
                tableView.reloadData()
                tableView.layoutIfNeeded()
            }
        }
    }

    private func configurePlaybackAppearance(for cell: UITableViewCell, at indexPath: IndexPath) {
        let isCurrentTrack = isPlayingHymn(at: indexPath.row)
        let backgroundColor = isCurrentTrack
            ? GlobalConstants.kColor_GoldColor.withAlphaComponent(0.28)
            : AppAppearance.cellCreamColor
        cell.backgroundColor = backgroundColor
        cell.contentView.backgroundColor = .clear
        cell.accessibilityTraits = isCurrentTrack
            ? [.button, .selected]
            : [.button]

        if plDetail.isEditing {
            let grabber = UIImageView(
                image: UIImage(
                    systemName: "line.3.horizontal",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
                )
            )
            grabber.tintColor = GlobalConstants.kColor_DarkColor
            grabber.accessibilityLabel = "Drag to reorder"
            cell.accessoryView = grabber
        } else if isCurrentTrack {
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
    
    func checkPlayerRunning() -> Bool {
        let player = AlhanPlayer.sharedInstance
        guard player.hasCurrentItem else {
            samePlaylist = false
            return false
        }

        let currentFileName = player.currentTrackURL?.lastPathComponent
        samePlaylist = playlistHymns.contains { hymn in
            guard let hymnURL = URL(string: hymn.HymnURL) else { return false }
            return hymnURL.lastPathComponent == currentFileName
        }

        // Opening a playlist is navigation only. Playback changes only when the
        // person explicitly selects a hymn or starts/shuffles the playlist.
        return player.isPlaying
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
        
        
       
        self.navigationItem.setRightBarButtonItems([editButtonItem, shuffleButton], animated: true)
        
       
            // Pause individual hymn if running
            if (AlhanPlayer.sharedInstance.player.rate == 1.0 ) {
                print("### Hymn player was on")
                AlhanPlayer.sharedInstance.player.pause()
            }

        
        var playableTracks = [AlhanPlayer.Track]()
        var playableStartIndex: Int? = startIndex == nil ? 0 : nil
        for (playlistIndex, hymnURL) in playlistHymns.enumerated() {
            
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
            
            
            let englishTitle: String?
            if let hymnID = hymnURL.HymnID {
                englishTitle = DBManager.shared.loadHymnDescription(withID: hymnID)
            } else {
                englishTitle = nil
            }

            if playlistIndex == startIndex {
                playableStartIndex = playableTracks.count
            }
            playableTracks.append(
                .init(
                    url: hymnAudioURL!,
                    title: hymnURL.HymnName ?? "iAlhan",
                    systemTitle: englishTitle,
                    albumTitle: title
                )
            )
            print("****** HYMN URL TO PLAY: \(String(describing: hymnAudioURL))")
            
            //AlhanPlayer.sharedInstance.playWithURL(playableURL: hymnURL)
            }
        }
            
        if !playableTracks.isEmpty {
            let queuedTracks = shuffled ? playableTracks.shuffled() : playableTracks
            let queueStartIndex = shuffled ? 0 : (playableStartIndex ?? 0)
            AlhanPlayer.sharedInstance.loadQueue(
                queuedTracks,
                startingAt: queueStartIndex,
                autoplay: true
            )
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
            self.navigationItem.setRightBarButtonItems([editButtonItem, shuffleButton], animated: true)
        
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

