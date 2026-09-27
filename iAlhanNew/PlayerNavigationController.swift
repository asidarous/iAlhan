import AVFoundation
import UIKit

@MainActor
final class PlayerNavigationController: UINavigationController, UINavigationControllerDelegate {
    private let player = AlhanPlayer.sharedInstance
    private let titleButton = UIButton(type: .system)
    private let progressView = UISlider()
    private let playPauseButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    private var playbackSourceViewController: UIViewController?
    private var miniPlayerItems = [UIBarButtonItem]()
    private var playbackTimeObserver: Any?
    private var trackChangeObserver: NSObjectProtocol?
    private var miniPlayerWidthConstraint: NSLayoutConstraint?
    private var isScrubbing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureMiniPlayer()
        observePlayer()
        updateMiniPlayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        miniPlayerWidthConstraint?.constant = max(
            280,
            view.safeAreaLayoutGuide.layoutFrame.width - 32
        )
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let source = topViewController
        let shouldKeepPlaying = player.intendsToPlay
        let poppedViewController = super.popViewController(animated: animated)

        if let source,
           source is HymnDetailViewController || source is PlaylistDetailVC,
           player.hasCurrentItem {
            playbackSourceViewController = source
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            if shouldKeepPlaying && self.player.hasCurrentItem && !self.player.isPlaying {
                self.player.play()
            }
            self.updateMiniPlayer()
        }
        return poppedViewController
    }

    private func configureMiniPlayer() {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        if #available(iOS 27.0, *) {
            appearance.backgroundColor = AppAppearance.playerSurfaceColor
            appearance.shadowColor = AppAppearance.playerBorderColor
        } else {
            appearance.backgroundColor = AppAppearance.cellCreamColor
            appearance.shadowColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.55)
        }
        toolbar.standardAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        toolbar.isTranslucent = false
        toolbar.compactScrollEdgeAppearance = appearance
        toolbar.tintColor = GlobalConstants.kColor_DarkColor

        titleButton.contentHorizontalAlignment = .leading
        let miniPlayerTitleSize: CGFloat
        if #available(iOS 27.0, *) {
            miniPlayerTitleSize = 16
        } else {
            miniPlayerTitleSize = 17
        }
        titleButton.titleLabel?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(
            for: UIFont(name: "COPT", size: miniPlayerTitleSize)
                ?? UIFont.preferredFont(forTextStyle: .subheadline)
        )
        titleButton.titleLabel?.adjustsFontForContentSizeCategory = true
        titleButton.titleLabel?.lineBreakMode = .byTruncatingTail
        titleButton.setTitleColor(GlobalConstants.kColor_DarkColor, for: .normal)
        titleButton.accessibilityHint = "Returns to the full player"
        titleButton.addTarget(self, action: #selector(openPlaybackSource), for: .touchUpInside)

        progressView.minimumValue = 0
        progressView.maximumValue = 1
        progressView.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        progressView.maximumTrackTintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.12)
        progressView.thumbTintColor = GlobalConstants.kColor_DarkColor
        progressView.accessibilityLabel = "Playback position"
        progressView.accessibilityHint = "Swipe up or down to seek through the hymn"
        progressView.addTarget(self, action: #selector(scrubbingDidBegin), for: .touchDown)
        progressView.addTarget(self, action: #selector(scrubberValueChanged), for: .valueChanged)
        progressView.addTarget(
            self,
            action: #selector(scrubbingDidEnd),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )

        configureButton(
            playPauseButton,
            action: #selector(togglePlayback),
            accessibilityLabel: "Play"
        )
        configureButton(
            nextButton,
            imageName: "forward.end.fill",
            action: #selector(playNext),
            accessibilityLabel: "Next hymn"
        )
        configureButton(
            closeButton,
            imageName: "xmark",
            action: #selector(closePlayer),
            accessibilityLabel: "Stop playback"
        )

        let titleStack = UIStackView(arrangedSubviews: [titleButton, progressView])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let controls = UIStackView(arrangedSubviews: [
            titleStack,
            playPauseButton,
            nextButton,
            closeButton
        ])
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 10
        controls.frame = CGRect(x: 0, y: 0, width: max(280, view.bounds.width - 32), height: 44)
        controls.heightAnchor.constraint(equalToConstant: 44).isActive = true

        if #unavailable(iOS 27.0) {
            controls.backgroundColor = AppAppearance.cellCreamColor
            controls.layer.cornerRadius = 12
            controls.layer.cornerCurve = .continuous
            controls.layer.borderWidth = 1.5
            controls.layer.borderColor = GlobalConstants.kColor_DarkColor.cgColor
            controls.isLayoutMarginsRelativeArrangement = true
            controls.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 2,
                leading: 10,
                bottom: 2,
                trailing: 10
            )
        }

        titleStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        [playPauseButton, nextButton, closeButton].forEach {
            $0.widthAnchor.constraint(equalToConstant: 36).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 36).isActive = true
        }

        miniPlayerWidthConstraint = controls.widthAnchor.constraint(
            equalToConstant: max(280, view.bounds.width - 32)
        )
        miniPlayerWidthConstraint?.isActive = true

        miniPlayerItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: controls),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        setToolbarHidden(true, animated: false)
    }

    private func configureButton(
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

    private func updateMiniPlayer() {
        let title = player.currentTrackTitle ?? "Now Playing"
        titleButton.setTitle(title, for: .normal)
        titleButton.accessibilityLabel = title

        let duration = player.duration
        progressView.isEnabled = duration > 0
        if !isScrubbing {
            progressView.value = duration > 0
                ? Float(player.currentTime / duration)
                : 0
        }

        let playSymbol = player.isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: playSymbol), for: .normal)
        playPauseButton.accessibilityLabel = player.isPlaying ? "Pause" : "Play"
        nextButton.isEnabled = player.canAdvance
        updateMiniPlayerVisibility(animated: false)
    }

    private func updateMiniPlayerVisibility(animated: Bool) {
        let isFullPlayerVisible =
            topViewController is HymnDetailViewController
            || topViewController is PlaylistDetailVC
        let shouldShow = player.hasCurrentItem && !isFullPlayerVisible
        if shouldShow {
            topViewController?.toolbarItems = miniPlayerItems
        }
        setToolbarHidden(!shouldShow, animated: animated)
    }

    @objc private func scrubbingDidBegin() {
        isScrubbing = true
    }

    @objc private func scrubberValueChanged() {
        guard !isScrubbing else { return }
        seekToScrubberPosition()
    }

    @objc private func scrubbingDidEnd() {
        seekToScrubberPosition()
        isScrubbing = false
    }

    private func seekToScrubberPosition() {
        guard player.duration > 0 else { return }
        player.seek(to: Double(progressView.value) * player.duration)
    }

    @objc private func togglePlayback() {
        player.togglePlayback()
        updateMiniPlayer()
    }

    @objc private func playNext() {
        player.advanceToNextItem()
        updateMiniPlayer()
    }

    @objc private func closePlayer() {
        player.clear()
        playbackSourceViewController = nil
        updateMiniPlayer()
    }

    @objc private func openPlaybackSource() {
        guard let playbackSourceViewController,
              playbackSourceViewController.navigationController == nil
        else { return }

        setToolbarHidden(true, animated: false)
        pushViewController(playbackSourceViewController, animated: true)
    }

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        if let current = topViewController,
           current !== viewController,
           (current is HymnDetailViewController || current is PlaylistDetailVC),
           player.hasCurrentItem {
            playbackSourceViewController = current
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        updateMiniPlayerVisibility(animated: true)
    }
}
