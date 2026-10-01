import AVFoundation
import UIKit

@MainActor
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let player = AlhanPlayer.sharedInstance
    private let miniPlayer = UIView()
    private let titleLabel = UILabel()
    // Kept separately from `titleLabel.font` because once `titleLabel.attributedText`
    // is set (below), reading `titleLabel.font` back reflects whatever font the *last*
    // title happened to use (Coptic, or GeezaPro for an Arabic title) rather than this
    // label's intended base font — and this update runs repeatedly on a timer.
    private let titleFont = AppAppearance.copticFont(ofSize: 16, relativeTo: .subheadline)
    private let elapsedTimeLabel = UILabel()
    private let scrubber = UISlider()
    private let durationTimeLabel = UILabel()
    private let previousButton = UIButton(type: .system)
    private let playPauseButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private var trackChangeObserver: NSObjectProtocol?
    private var playbackTimeObserver: Any?
    private var isScrubbing = false

    init(browseNavigationController: PlayerNavigationController) {
        super.init(nibName: nil, bundle: nil)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let playlists = storyboard.instantiateViewController(
            withIdentifier: "PlayListViewController"
        )
        let playlistsNavigationController = PlayerNavigationController(
            rootViewController: playlists
        )
        let settingsNavigationController = PlayerNavigationController(
            rootViewController: SettingsViewController(style: .insetGrouped)
        )

        configure(
            browseNavigationController,
            title: "Hymns",
            image: "square.grid.2x2.fill"
        )
        configure(
            playlistsNavigationController,
            title: "Playlists",
            image: "music.note.list"
        )
        configure(
            settingsNavigationController,
            title: "Settings",
            image: "gearshape.fill"
        )

        viewControllers = [
            browseNavigationController,
            playlistsNavigationController,
            settingsNavigationController
        ]
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureMiniPlayer()
        observePlayer()
        updateMiniPlayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        miniPlayer.transform = .identity
        let tabBarFrame = view.convert(tabBar.bounds, from: tabBar)
        let verticalOffset = tabBarFrame.minY - 5 - miniPlayer.frame.maxY
        miniPlayer.transform = CGAffineTransform(
            translationX: 0,
            y: verticalOffset
        )
    }

    private func configure(
        _ navigationController: UINavigationController,
        title: String,
        image: String
    ) {
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: image),
            selectedImage: nil
        )
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppAppearance.cellCreamColor
        appearance.shadowColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.16)

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = GlobalConstants.kColor_DarkColor
        tabBar.unselectedItemTintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.55)
    }

    private func configureMiniPlayer() {
        miniPlayer.translatesAutoresizingMaskIntoConstraints = false
        miniPlayer.backgroundColor = AppAppearance.cellCreamColor
        miniPlayer.layer.cornerRadius = 16
        miniPlayer.layer.cornerCurve = .continuous
        miniPlayer.layer.borderWidth = 1
        miniPlayer.layer.borderColor = AppAppearance.playerBorderColor.cgColor
        miniPlayer.layer.shadowColor = UIColor.black.cgColor
        miniPlayer.layer.shadowOpacity = 0.14
        miniPlayer.layer.shadowRadius = 10
        miniPlayer.layer.shadowOffset = CGSize(width: 0, height: 4)
        miniPlayer.isHidden = true

        titleLabel.font = titleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = GlobalConstants.kColor_DarkColor
        titleLabel.lineBreakMode = .byTruncatingTail

        configureTimeLabel(elapsedTimeLabel, alignment: .right)
        configureTimeLabel(durationTimeLabel, alignment: .left)

        scrubber.minimumValue = 0
        scrubber.maximumValue = 1
        scrubber.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        scrubber.maximumTrackTintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.15)
        scrubber.thumbTintColor = GlobalConstants.kColor_DarkColor
        scrubber.accessibilityLabel = "Playback position"
        scrubber.accessibilityHint = "Adjust to seek through the hymn"
        scrubber.addTarget(self, action: #selector(scrubbingDidBegin), for: .touchDown)
        scrubber.addTarget(self, action: #selector(scrubberValueChanged), for: .valueChanged)
        scrubber.addTarget(
            self,
            action: #selector(scrubbingDidEnd),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )

        configurePlayerButton(
            previousButton,
            imageName: "backward.end.fill",
            action: #selector(playPrevious),
            accessibilityLabel: "Previous hymn"
        )
        configurePlayerButton(
            playPauseButton,
            action: #selector(togglePlayback),
            accessibilityLabel: "Play"
        )
        configurePlayerButton(
            nextButton,
            imageName: "forward.end.fill",
            action: #selector(playNext),
            accessibilityLabel: "Next hymn"
        )
        configurePlayerButton(
            closeButton,
            imageName: "xmark",
            action: #selector(closePlayer),
            accessibilityLabel: "Stop playback"
        )

        let buttons = UIStackView(arrangedSubviews: [
            previousButton,
            playPauseButton,
            nextButton,
            closeButton
        ])
        buttons.axis = .horizontal
        buttons.alignment = .center
        buttons.spacing = 6

        let header = UIStackView(arrangedSubviews: [titleLabel, buttons])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8

        let timeline = UIStackView(arrangedSubviews: [
            elapsedTimeLabel,
            scrubber,
            durationTimeLabel
        ])
        timeline.axis = .horizontal
        timeline.alignment = .center
        timeline.spacing = 8

        let controls = UIStackView(arrangedSubviews: [header, timeline])
        controls.translatesAutoresizingMaskIntoConstraints = false
        controls.axis = .vertical
        controls.spacing = 2
        controls.isLayoutMarginsRelativeArrangement = true
        controls.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 5,
            leading: 12,
            bottom: 5,
            trailing: 10
        )

        miniPlayer.addSubview(controls)
        view.addSubview(miniPlayer)

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        scrubber.setContentHuggingPriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            miniPlayer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            miniPlayer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            miniPlayer.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -5
            ),
            miniPlayer.heightAnchor.constraint(equalToConstant: 76),

            controls.leadingAnchor.constraint(equalTo: miniPlayer.leadingAnchor),
            controls.trailingAnchor.constraint(equalTo: miniPlayer.trailingAnchor),
            controls.topAnchor.constraint(equalTo: miniPlayer.topAnchor),
            controls.bottomAnchor.constraint(equalTo: miniPlayer.bottomAnchor),

            elapsedTimeLabel.widthAnchor.constraint(equalToConstant: 42),
            durationTimeLabel.widthAnchor.constraint(equalToConstant: 42),
            previousButton.widthAnchor.constraint(equalToConstant: 36),
            previousButton.heightAnchor.constraint(equalToConstant: 36),
            playPauseButton.widthAnchor.constraint(equalToConstant: 36),
            playPauseButton.heightAnchor.constraint(equalToConstant: 36),
            nextButton.widthAnchor.constraint(equalToConstant: 36),
            nextButton.heightAnchor.constraint(equalToConstant: 36),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        view.bringSubviewToFront(tabBar)
        view.bringSubviewToFront(miniPlayer)
    }

    private func configurePlayerButton(
        _ button: UIButton,
        imageName: String? = nil,
        action: Selector,
        accessibilityLabel: String
    ) {
        if let imageName {
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }
        button.tintColor = GlobalConstants.kColor_DarkColor
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureTimeLabel(
        _ label: UILabel,
        alignment: NSTextAlignment
    ) {
        let baseFont = UIFont.monospacedDigitSystemFont(
            ofSize: 11,
            weight: .regular
        )
        label.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(
            for: baseFont
        )
        label.adjustsFontForContentSizeCategory = true
        label.text = "0:00"
        label.textAlignment = alignment
        label.textColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.78)
    }

    private func observePlayer() {
        trackChangeObserver = NotificationCenter.default.addObserver(
            forName: .alhanPlayerCurrentTrackDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMiniPlayer()
            }
        }

        playbackTimeObserver = player.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMiniPlayer()
            }
        }
    }

    func updateMiniPlayer() {
        let visibleViewController = (selectedViewController as? UINavigationController)?.visibleViewController
        let isFullPlayerVisible = visibleViewController is HymnDetailViewController
            || visibleViewController is PlaylistDetailVC
        miniPlayer.isHidden = !player.hasCurrentItem || isFullPlayerVisible
        guard player.hasCurrentItem else { return }

        let trackTitle = player.currentTrackTitle ?? "Now Playing"
        // Some hymn titles are Arabic rather than Coptic text; route through the shared
        // helper so those render with correctly joined Arabic letterforms instead of
        // the Coptic font's disconnected glyphs. This must be the only thing setting
        // text/font/color on titleLabel after this point: UILabel overwrites
        // attributedText's per-run attributes if `.font` or `.textColor` is assigned
        // afterward.
        titleLabel.attributedText = AppAppearance.attributedStringHandlingArabic(
            trackTitle,
            baseFont: titleFont,
            extraAttributes: [.foregroundColor: GlobalConstants.kColor_DarkColor]
        )
        titleLabel.accessibilityLabel = trackTitle

        let duration = player.duration
        scrubber.isEnabled = duration > 0
        if !isScrubbing {
            let currentTime = player.currentTime
            scrubber.value = duration > 0
                ? Float(currentTime / duration)
                : 0
            elapsedTimeLabel.text = formattedTime(currentTime)
        }
        durationTimeLabel.text = formattedTime(duration)
        scrubber.accessibilityValue = "\(elapsedTimeLabel.text ?? "0:00") of \(durationTimeLabel.text ?? "0:00")"

        let playSymbol = player.isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: playSymbol), for: .normal)
        playPauseButton.accessibilityLabel = player.isPlaying ? "Pause" : "Play"
        let showsPlaylistControls = player.playbackContext == .playlist
        previousButton.isHidden = !showsPlaylistControls
        nextButton.isHidden = !showsPlaylistControls
        previousButton.isEnabled = player.canGoBack
        nextButton.isEnabled = player.canAdvance
    }

    @objc private func scrubbingDidBegin() {
        isScrubbing = true
    }

    @objc private func scrubberValueChanged() {
        let previewTime = Double(scrubber.value) * player.duration
        elapsedTimeLabel.text = formattedTime(previewTime)
        scrubber.accessibilityValue = "\(formattedTime(previewTime)) of \(formattedTime(player.duration))"
    }

    @objc private func scrubbingDidEnd() {
        let targetTime = Double(scrubber.value) * player.duration
        player.seek(to: targetTime)
        isScrubbing = false
        updateMiniPlayer()
        UIAccessibility.post(
            notification: .announcement,
            argument: "Skipped to \(formattedTime(targetTime))"
        )
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let totalSeconds = Int(time.rounded(.down))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    @objc private func togglePlayback() {
        player.togglePlayback()
        updateMiniPlayer()
    }

    @objc private func playPrevious() {
        player.returnToPreviousItem()
        updateMiniPlayer()
    }

    @objc private func playNext() {
        player.advanceToNextItem()
        updateMiniPlayer()
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        updateMiniPlayer()
    }

    @objc private func closePlayer() {
        player.clear()
        updateMiniPlayer()
    }
}
