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

/// A full-width shading band drawn behind a stanza row, positioned by tracking the
/// scroll offset of whichever text view supplied its vertical measurements.
private struct StanzaBand {
    let view: UIView
    let referenceTextView: UITextView
    let contentY: CGFloat
    let height: CGFloat
}

@MainActor var playlistInstructions: Bool = false
class HymnDetailViewController: UIViewController, UITextViewDelegate{
    @IBOutlet var HymnDetailView: UIView!
    @IBOutlet var visualEffectView: UIVisualEffectView!

    @IBOutlet var ToolBar: UIToolbar!
    @IBOutlet var HymnTextEnglish: UITextView!
    @IBOutlet var HymnTextCoptic: UITextView!
    
    private let progressBar = UISlider()
    private let elapsedTimeLabel = UILabel()
    private let durationTimeLabel = UILabel()
    private var progressBarItem = UIBarButtonItem()
    private var playbackTimeObserver: Any?
    private var isSeeking = false
    private var displayedDuration: TimeInterval = 0
    private var alignedTextWidth: CGFloat = 0
    private let columnDivider = UIView()
    private var sideBySideColumnConstraints = [NSLayoutConstraint]()
    private var stackedColumnConstraints = [NSLayoutConstraint]()
    private var sideBySideDividerConstraints = [NSLayoutConstraint]()
    private var stackedDividerConstraints = [NSLayoutConstraint]()
    private var stanzaBands = [StanzaBand]()

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
    let alert = UIAlertController(title: "No Internet Connection", message: "Please make sure you are connected to the internet to be able to stream hymns. Meanwhile you can listen to downloaded content offline. ", preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if playerItem != nil {
            guard playerItem.status.rawValue == AVPlayerItem.Status.readyToPlay.rawValue else {return}
        }
        view.backgroundColor = AppAppearance.cellCreamColor
        visualEffectView.effect = nil
        visualEffectView.backgroundColor = AppAppearance.cellCreamColor
        visualEffectView.contentView.backgroundColor = AppAppearance.cellCreamColor

        
        
        if (self.canBecomeFirstResponder){
            self.becomeFirstResponder()
        }
        // Initialize the shared playback service. It owns the audio session,
        // interruption handling, and lock-screen controls for the whole app.
        _ = AlhanPlayer.sharedInstance
        
        
        // file download handling
        //print("8888888888" )
        //print ((hymnDetail?[0].hymnAudio)!)
        guard let hymn = hymnDetail?.first,
              let audioString = hymn.hymnAudio,
              let audioURL = URL(string: audioString) else {
            print("HymnDetailViewController requires a hymn with a valid audio URL")
            navigationController?.popViewController(animated: true)
            return
        }

        localDir = getDirectory(url: audioString)
        //print("DIRECTORY \(localDir)")
        
        HymnTextEnglish.delegate = self
        HymnTextCoptic.delegate = self
        configureHymnText()
        configureColumnLayout()
        configureAddButton()
        
        configureNavigationBarAppearance(title: hymn.hymnName)
        hymnAudioURL = audioURL
        
        // check to see if the file is local and thus play from local
        let localPath = documentsDirectoryURL.appendingPathComponent(localDir)
        let destinationUrl = localPath.appendingPathComponent((hymnAudioURL?.lastPathComponent)!)
        
        if FileManager.default.fileExists(atPath: destinationUrl.path){
            hymnAudioURL = destinationUrl
            fileIsLocal = true
            // print("!!!!!! playing the local file - TOP")
        }
        /**
        //new progress bar
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(HymnDetailViewController.trackAudio), userInfo: nil, repeats: true)
        
        //Get progress bar width based on orientation
        var pbWidth: CGFloat!
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact
            print("%%%% I'm compact")
            
            pbWidth = HymnDetailView.frame.width * 0.65
            print("WIDTH: \(String(describing: pbWidth))")
            
        } else {
            // Regular
            print("%%%% I'm regular")
            pbWidth = HymnDetailView.frame.width * 0.82
            print("WIDTH: \(String(describing: pbWidth))")
        }
        
        //pbWidth = HymnDetailView.frame.width * 0.85
        print("The width: \(String(describing: pbWidth))")
        
        progressBar = UISlider(frame:CGRect(x: 10, y: 100, width: pbWidth, height: 20))
        progressBar.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        progressBar.thumbTintColor = GlobalConstants.kColor_DarkColor
        progressBar.setThumbImage(UIImage(named: "thumb"), for: UIControl.State.normal)
        progressBar.setThumbImage(UIImage(named: "thumb"), for: UIControl.State.highlighted)
        progressBar.isUserInteractionEnabled = true
        
        // Add observer to update the slider as the player progresses
            AlhanPlayer.sharedInstance.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] time in
                    if let duration = self?.playerItem.duration {
                        let totalSeconds = CMTimeGetSeconds(duration)
                        let currentSeconds = CMTimeGetSeconds(time)
                        self!.progressBar.value = Float(currentSeconds / totalSeconds)
                    }
                }
        
        
        progressBar.addTarget(self, action: #selector(HymnDetailViewController.Seek), for: .allEvents)
        //progressBar.autoresizingMask = .flexibleWidth
        //progressBar.sizeToFit()
        **/
        
        
        print("PLAYER ITEM At view Did Load : -- \(String(describing: hymnAudioURL))")
        ToolBar.isHidden = false
        ToolBar.accessibilityElementsHidden = false
        ToolBar.isAccessibilityElement = false
        configurePlayerBarAppearance()
        pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.pause, target: self, action: #selector(HymnDetailViewController.pauseButtonTapped))
        playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play, target: self, action: #selector(HymnDetailViewController.playButtonTapped))
        saveButton = UIBarButtonItem(image: UIImage(systemName: "arrow.down.circle"), landscapeImagePhone: nil, style: .done, target: self, action: #selector(HymnDetailViewController.saveFile))
        saveButton.accessibilityLabel = "Download"
        deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.trash, target: self, action: #selector(HymnDetailViewController.deleteFile))
        configureProgressBar()
        
        //*******
        //*** check to see if there is a hymn playing
        //*******
        let isCurrentHymnPlaying = checkPlayerRunning(audioString: hymnAudioURL.absoluteString)
        if isCurrentHymnPlaying == false {
            
            playerItem = AVPlayerItem(url: hymnAudioURL)
            AlhanPlayer.sharedInstance.load(
                .init(
                    url: hymnAudioURL,
                    title: hymnDetail?[0].hymnName ?? "iAlhan",
                    systemTitle: hymnDetail?[0].hymnDescription
                )
            )
            
            
            updateToolbar(isPlaying: false)
            
        } else //*** if it is playing the hymn *****
        {
            
            updateToolbar(isPlaying: true)
            //            updater = CADisplayLink(target: self, selector: #selector(HymnDetailViewController.trackAudio))
            //            updater.preferredFramesPerSecond = 60
            //            updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
            //
        }
        
    }

    private func configureNavigationBarAppearance(title: String) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = GlobalConstants.kColor_DarkColor

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        navigationItem.hidesBackButton = true
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = GlobalConstants.kColor_GoldColor

        let titleLabel = UILabel()
        let titleFont = AppAppearance.copticFont(ofSize: 22, relativeTo: .title2)
        titleLabel.font = titleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.accessibilityTraits = .header
        // Some hymn titles are Arabic rather than Coptic text; route through the shared
        // helper so those render with correctly joined Arabic letterforms instead of
        // the Coptic font's disconnected glyphs. This must be the last property set
        // here that touches text/font/color: UILabel overwrites attributedText's
        // per-run attributes if `.font` or `.textColor` is assigned afterward, so both
        // are folded into the attributed string instead (alignment is embedded too, as
        // a paragraph style, since it's authoritative over the `.textAlignment` set
        // above regardless of ordering).
        let centeredStyle = NSMutableParagraphStyle()
        centeredStyle.alignment = .center
        titleLabel.attributedText = AppAppearance.attributedStringHandlingArabic(
            title,
            baseFont: titleFont,
            extraAttributes: [
                .foregroundColor: GlobalConstants.kColor_GoldColor,
                .paragraphStyle: centeredStyle
            ]
        )
        navigationItem.titleView = titleLabel
    }

    private func configurePlayerBarAppearance() {
        ToolBar.tintColor = GlobalConstants.kColor_DarkColor

        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = AppAppearance.playerSurfaceColor
        appearance.shadowColor = AppAppearance.playerBorderColor

        ToolBar.standardAppearance = appearance
        ToolBar.compactAppearance = appearance
        ToolBar.scrollEdgeAppearance = appearance
        ToolBar.compactScrollEdgeAppearance = appearance
    }

    private func configureHymnText() {
        let englishBaseFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        HymnTextEnglish.font = ReadingPreferences.scaledFont(
            baseFont: englishBaseFont,
            relativeTo: .body,
            compatibleWith: traitCollection
        )
        HymnTextEnglish.adjustsFontForContentSizeCategory = true
        // Left transparent so the full-width stanza shading behind the text (added to the
        // parent view, which is already the cream color) can show through edge to edge.
        HymnTextEnglish.backgroundColor = .clear
        HymnTextEnglish.textColor = GlobalConstants.kColor_DarkColor
        // The two columns scroll together (see scrollViewDidScroll), so a scroll
        // indicator on each is redundant and just adds visual clutter.
        HymnTextEnglish.showsVerticalScrollIndicator = false
        HymnTextEnglish.showsHorizontalScrollIndicator = false

        let copticBaseFont = AppAppearance.copticBaseFont(ofSize: 21)
        HymnTextCoptic.font = ReadingPreferences.scaledFont(
            baseFont: copticBaseFont,
            relativeTo: .body,
            compatibleWith: traitCollection
        )
        HymnTextCoptic.adjustsFontForContentSizeCategory = true
        HymnTextCoptic.backgroundColor = .clear
        HymnTextCoptic.textColor = GlobalConstants.kColor_DarkColor
        HymnTextCoptic.showsVerticalScrollIndicator = false
        HymnTextCoptic.showsHorizontalScrollIndicator = false
    }

    private func alignHymnParagraphs() {
        guard let hymn = hymnDetail?.first,
              let copticText = hymn.hymnCoptic,
              let englishText = hymn.hymnEnglish,
              let copticFont = HymnTextCoptic.font,
              let englishFont = HymnTextEnglish.font else { return }

        let copticWidth = usableTextWidth(in: HymnTextCoptic)
        let englishWidth = usableTextWidth(in: HymnTextEnglish)
        guard copticWidth > 0, englishWidth > 0 else { return }

        let currentWidth = copticWidth + englishWidth
        guard abs(currentWidth - alignedTextWidth) > 0.5
                || HymnTextCoptic.attributedText.length == 0 else { return }
        alignedTextWidth = currentWidth

        let copticParagraphs = lines(in: copticText)
        let englishParagraphs = lines(in: englishText)
        let paragraphCount = max(copticParagraphs.count, englishParagraphs.count)
        let sharedLineHeight = max(copticFont.lineHeight, englishFont.lineHeight)
        let copticAdvances = renderedLineAdvances(
            copticParagraphs,
            font: copticFont,
            width: copticWidth,
            lineHeight: sharedLineHeight
        )
        let englishAdvances = renderedLineAdvances(
            englishParagraphs,
            font: englishFont,
            width: englishWidth,
            lineHeight: sharedLineHeight
        )
        let copticResult = NSMutableAttributedString()
        let englishResult = NSMutableAttributedString()
        // A small fixed gap inserted between stanzas (never inside one), scaled with the
        // line height so it grows with Dynamic Type instead of staying a fixed point size.
        let rowSpacing = sharedLineHeight * 0.4
        // Both columns consume exactly `rowAdvance` of vertical space per stanza (that's
        // what the paragraphSpacing padding above guarantees), so a single cumulative
        // offset describes the top of every stanza in both text views' content coordinates.
        var shadedRows = [(contentY: CGFloat, height: CGFloat)]()
        var cumulativeY: CGFloat = 0

        for index in 0..<paragraphCount {
            let copticParagraph = index < copticParagraphs.count ? copticParagraphs[index] : ""
            let englishParagraph = index < englishParagraphs.count ? englishParagraphs[index] : ""
            let copticAdvance = index < copticAdvances.count ? copticAdvances[index] : sharedLineHeight
            let englishAdvance = index < englishAdvances.count ? englishAdvances[index] : sharedLineHeight
            let rowAdvance = max(copticAdvance, englishAdvance)
            let isLastRow = index == paragraphCount - 1
            // The gap is added on top of the row's own height, after the shaded band's
            // rect is recorded, so both languages still start flush at the top of the row
            // and the extra breathing room shows the plain background between rows.
            let trailingGap = isLastRow ? 0 : rowSpacing

            if index % 2 == 1 {
                shadedRows.append((contentY: cumulativeY, height: rowAdvance))
            }
            cumulativeY += rowAdvance + trailingGap

            appendParagraph(
                copticParagraph,
                to: copticResult,
                font: copticFont,
                lineHeight: sharedLineHeight,
                paragraphSpacing: rowAdvance - copticAdvance + trailingGap,
                includesSeparator: index < paragraphCount - 1
            )
            appendParagraph(
                englishParagraph,
                to: englishResult,
                font: englishFont,
                lineHeight: sharedLineHeight,
                paragraphSpacing: rowAdvance - englishAdvance + trailingGap,
                includesSeparator: index < paragraphCount - 1
            )
        }

        HymnTextCoptic.attributedText = copticResult
        HymnTextEnglish.attributedText = englishResult

        rebuildStanzaBands(shadedRows: shadedRows)
    }

    /// Rebuilds the full-width shading bands behind the shaded stanzas. Each band is a
    /// sibling of the (now transparent) text views, sitting behind them so the tint
    /// reaches both screen edges and continues under the divider between the columns,
    /// while the parent view's cream background shows through everywhere else.
    private func rebuildStanzaBands(shadedRows: [(contentY: CGFloat, height: CGFloat)]) {
        stanzaBands.forEach { $0.view.removeFromSuperview() }
        stanzaBands.removeAll()
        guard !shadedRows.isEmpty else { return }

        let usesStackedLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        var newBands = [StanzaBand]()
        for row in shadedRows {
            // In the side-by-side layout, Coptic and English share the same top edge, so
            // Coptic's own scroll position is enough to place one band spanning both
            // columns. In the stacked (accessibility) layout the columns scroll as two
            // separate blocks, so each needs its own band tracking its own text view.
            newBands.append(makeStanzaBand(referenceTextView: HymnTextCoptic, contentY: row.contentY, height: row.height))
            if usesStackedLayout {
                newBands.append(makeStanzaBand(referenceTextView: HymnTextEnglish, contentY: row.contentY, height: row.height))
            }
        }
        stanzaBands = newBands

        // Keep the text and the column divider readable above the shading.
        view.bringSubviewToFront(columnDivider)
        view.bringSubviewToFront(HymnTextCoptic)
        view.bringSubviewToFront(HymnTextEnglish)
        view.bringSubviewToFront(ToolBar)

        updateStanzaBandPositions()
    }

    private func makeStanzaBand(referenceTextView: UITextView, contentY: CGFloat, height: CGFloat) -> StanzaBand {
        let band = UIView()
        band.backgroundColor = AppAppearance.stanzaShadeColor
        band.isUserInteractionEnabled = false
        view.addSubview(band)
        return StanzaBand(view: band, referenceTextView: referenceTextView, contentY: contentY, height: height)
    }

    /// Repositions the shading bands to follow their reference text view's current scroll
    /// offset, so the shading scrolls in lockstep with the stanza it belongs to.
    private func updateStanzaBandPositions() {
        for band in stanzaBands {
            let textView = band.referenceTextView
            let y = textView.frame.minY
                + textView.textContainerInset.top
                + band.contentY
                - textView.contentOffset.y
            band.view.frame = CGRect(x: 0, y: y, width: view.bounds.width, height: band.height)
        }
    }

    private func lines(in text: String) -> [String] {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func usableTextWidth(in textView: UITextView) -> CGFloat {
        textView.bounds.width
            - textView.textContainerInset.left
            - textView.textContainerInset.right
            - (textView.textContainer.lineFragmentPadding * 2)
    }

    private func renderedLineAdvances(
        _ lines: [String],
        font: UIFont,
        width: CGFloat,
        lineHeight: CGFloat
    ) -> [CGFloat] {
        guard !lines.isEmpty else { return [] }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        let joinedText = lines.joined(separator: "\n")
        let textStorage = NSTextStorage(
            string: joinedText,
            attributes: [.font: font, .paragraphStyle: paragraphStyle]
        )
        // Match the font substitution applied in `appendParagraph` below, so a line
        // whose wrapping changes once its Arabic runs switch to an Arabic-shaping font
        // is measured the same way it will actually render. Otherwise the Coptic and
        // English row heights could drift apart for any stanza containing Arabic text.
        AppAppearance.applyArabicFontOverride(
            to: textStorage,
            in: NSRange(location: 0, length: textStorage.length),
            pointSize: font.pointSize
        )
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(
            size: CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)

        var characterIndex = 0
        var startPositions = [CGFloat]()
        for line in lines {
            let safeIndex = min(characterIndex, max(0, textStorage.length - 1))
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: safeIndex)
            startPositions.append(
                layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil).minY
            )
            characterIndex += (line as NSString).length + 1
        }

        let documentHeight = layoutManager.usedRect(for: textContainer).maxY
        return startPositions.enumerated().map { index, position in
            let nextPosition = index + 1 < startPositions.count
                ? startPositions[index + 1]
                : documentHeight
            return max(lineHeight, nextPosition - position)
        }
    }

    private func appendParagraph(
        _ text: String,
        to result: NSMutableAttributedString,
        font: UIFont,
        lineHeight: CGFloat,
        paragraphSpacing: CGFloat,
        includesSeparator: Bool
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.paragraphSpacing = includesSeparator ? paragraphSpacing : 0
        let value = text + (includesSeparator ? "\n" : "")

        let appendedRange = NSRange(location: result.length, length: (value as NSString).length)
        result.append(NSAttributedString(
            string: value,
            attributes: [
                .font: font,
                .foregroundColor: GlobalConstants.kColor_DarkColor,
                .paragraphStyle: paragraphStyle
            ]
        ))
        AppAppearance.applyArabicFontOverride(to: result, in: appendedRange, pointSize: font.pointSize)
    }

    private func configureColumnLayout() {
        let constraints = view.constraints
        guard
            let equalWidth = constraints.first(where: {
                $0.firstItem === HymnTextCoptic
                    && $0.firstAttribute == .width
                    && $0.secondItem === HymnTextEnglish
            }),
            let englishLeading = constraints.first(where: {
                $0.firstItem === HymnTextEnglish
                    && $0.firstAttribute == .leading
                    && $0.secondItem === HymnTextCoptic
            }),
            let englishTop = constraints.first(where: {
                $0.firstItem === HymnTextEnglish && $0.firstAttribute == .top
            }),
            let copticBottom = constraints.first(where: {
                $0.firstItem === ToolBar
                    && $0.firstAttribute == .top
                    && $0.secondItem === HymnTextCoptic
            })
        else { return }

        englishLeading.constant = 16
        sideBySideColumnConstraints = [
            equalWidth,
            englishLeading,
            englishTop,
            copticBottom
        ]

        stackedColumnConstraints = [
            HymnTextCoptic.trailingAnchor.constraint(equalTo: HymnTextEnglish.trailingAnchor),
            HymnTextEnglish.leadingAnchor.constraint(equalTo: HymnTextCoptic.leadingAnchor),
            HymnTextEnglish.topAnchor.constraint(equalTo: HymnTextCoptic.bottomAnchor, constant: 16),
            HymnTextCoptic.heightAnchor.constraint(equalTo: HymnTextEnglish.heightAnchor)
        ]

        columnDivider.translatesAutoresizingMaskIntoConstraints = false
        columnDivider.backgroundColor = .separator
        columnDivider.isAccessibilityElement = false
        view.addSubview(columnDivider)

        sideBySideDividerConstraints = [
            columnDivider.widthAnchor.constraint(equalToConstant: 1),
            columnDivider.centerXAnchor.constraint(
                equalTo: HymnTextCoptic.trailingAnchor,
                constant: 8
            ),
            columnDivider.topAnchor.constraint(equalTo: HymnTextCoptic.topAnchor, constant: 8),
            columnDivider.bottomAnchor.constraint(equalTo: HymnTextCoptic.bottomAnchor, constant: -8)
        ]
        stackedDividerConstraints = [
            columnDivider.heightAnchor.constraint(equalToConstant: 1),
            columnDivider.leadingAnchor.constraint(equalTo: HymnTextCoptic.leadingAnchor, constant: 8),
            columnDivider.trailingAnchor.constraint(equalTo: HymnTextCoptic.trailingAnchor, constant: -8),
            columnDivider.centerYAnchor.constraint(
                equalTo: HymnTextCoptic.bottomAnchor,
                constant: 8
            )
        ]

        updateColumnLayout()
    }

    private func updateColumnLayout() {
        guard !sideBySideColumnConstraints.isEmpty else { return }

        let usesStackedLayout = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        NSLayoutConstraint.deactivate(sideBySideColumnConstraints + stackedColumnConstraints)
        NSLayoutConstraint.deactivate(sideBySideDividerConstraints + stackedDividerConstraints)

        if usesStackedLayout {
            NSLayoutConstraint.activate(stackedColumnConstraints + stackedDividerConstraints)
        } else {
            NSLayoutConstraint.activate(sideBySideColumnConstraints + sideBySideDividerConstraints)
        }
    }

    private func configureAddButton() {
        let addButton = UIButton(type: .system)
        AppAppearance.configureRoundNavigationButton(
            addButton,
            systemImageName: "text.badge.plus",
            accessibilityLabel: "Add to playlist"
        )
        addButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        addButton.addTarget(self, action: #selector(addToPlaylistTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    }

    @objc private func addToPlaylistTapped() {
        performSegue(withIdentifier: "PlayList", sender: self)
    }
    
    private func configureProgressBar() {
        let availableWidth = max(180, min(260, view.bounds.width - 140))
        progressBar.minimumValue = 0
        progressBar.maximumValue = 1
        progressBar.minimumTrackTintColor = GlobalConstants.kColor_DarkColor
        progressBar.thumbTintColor = GlobalConstants.kColor_DarkColor
        let thumbConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: thumbConfiguration)
        progressBar.setThumbImage(thumbImage, for: .normal)
        progressBar.setThumbImage(thumbImage, for: .highlighted)
        progressBar.accessibilityLabel = "Playback position"
        progressBar.addTarget(self, action: #selector(beginSeeking), for: .touchDown)
        progressBar.addTarget(self, action: #selector(progressBarValueChanged), for: .valueChanged)
        progressBar.addTarget(self, action: #selector(endSeeking), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        configureTimeLabel(elapsedTimeLabel, alignment: .right)
        configureTimeLabel(durationTimeLabel, alignment: .left)

        let progressControls = UIStackView(arrangedSubviews: [
            elapsedTimeLabel,
            progressBar,
            durationTimeLabel
        ])
        progressControls.axis = .horizontal
        progressControls.alignment = .center
        progressControls.spacing = 4
        progressControls.frame = CGRect(x: 0, y: 0, width: availableWidth, height: 32)
        elapsedTimeLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        durationTimeLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        progressBarItem = UIBarButtonItem(customView: progressControls)
        updateProgressAccessibilityValue()
    }

    private func configureTimeLabel(_ label: UILabel, alignment: NSTextAlignment) {
        let baseFont = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        label.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(
            for: baseFont
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = GlobalConstants.kColor_DarkColor
        label.textAlignment = alignment
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.isAccessibilityElement = false
    }

    private func updateToolbar(isPlaying: Bool) {
        let playbackButton = isPlaying ? pauseButton : playButton
        let fileButton = fileIsLocal ? deleteButton : saveButton
        arrayOfButtons = [playbackButton, progressBarItem, fileButton]
        ToolBar.setItems(arrayOfButtons, animated: false)
    }

    private func startPlaybackTimeObserver() {
        guard playbackTimeObserver == nil else { return }

        playbackTimeObserver = AlhanPlayer.sharedInstance.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, !isSeeking else { return }

                let duration = AlhanPlayer.sharedInstance.duration
                guard duration > 0 else { return }

                displayedDuration = duration
                progressBar.maximumValue = Float(duration)
                progressBar.value = Float(time.seconds.isFinite ? time.seconds : 0)
                updateProgressAccessibilityValue()
            }
        }
    }

    private func stopPlaybackTimeObserver() {
        guard let playbackTimeObserver else { return }
        AlhanPlayer.sharedInstance.player.removeTimeObserver(playbackTimeObserver)
        self.playbackTimeObserver = nil
    }

    private func updateProgressAccessibilityValue() {
        let elapsed = max(0, TimeInterval(progressBar.value))
        elapsedTimeLabel.text = formattedTime(elapsed)
        durationTimeLabel.text = displayedDuration > 0 ? formattedTime(displayedDuration) : "--:--"
        progressBar.accessibilityValue = displayedDuration > 0
            ? "\(formattedTime(elapsed)) of \(formattedTime(displayedDuration))"
            : formattedTime(elapsed)
    }

    private func formattedTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%d:%02d", minutes, seconds)
    }

    @objc private func beginSeeking() {
        isSeeking = true
    }

    @objc private func progressBarValueChanged() {
        updateProgressAccessibilityValue()
    }

    @objc private func endSeeking() {
        AlhanPlayer.sharedInstance.seek(to: TimeInterval(progressBar.value))
        isSeeking = false
    }

    // MARK: Scroll control
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == HymnTextCoptic{
            HymnTextEnglish.contentOffset = HymnTextCoptic.contentOffset
        }else{
            HymnTextCoptic.contentOffset = HymnTextEnglish.contentOffset
        }
        updateStanzaBandPositions()
    }

    @objc func pauseCommandHandler(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
            // Perform your pause logic here
            // For example, pause your audio playback
        pause()
        //#selector(HymnDetailViewController.pause)
            // Return appropriate status
            return .success
        }
    // MARK: Audio controls
    
    @objc func finishedPlaying(myNotification: Notification) {
        progressBar.value = 0
        updateProgressAccessibilityValue()
        updateToolbar(isPlaying: false)
        AlhanPlayer.sharedInstance.resetTimer()
    }
    
    func play() {
        AlhanPlayer.sharedInstance.play()
    }
    
    
    @objc func pause() {
        AlhanPlayer.sharedInstance.pause()
    }
    

    
    @objc func playButtonTapped() {
        //print ("Here is the fileIsLocal variable: \(fileIsLocal)")
        //print ("Here is the Reachability: \(Reachability.isConnectedToNetwork())")
        
        if (!Reachability.isConnectedToNetwork()) && fileIsLocal == false{
            
             showAlertButton()
           
        
        } else {
            updateToolbar(isPlaying: true)
            play()
        }
    }
    
    @objc func pauseButtonTapped() {
        updateToolbar(isPlaying: false)
        pause()
    }
    
    func activateSession(completion: @escaping @MainActor @Sendable (Bool) -> Void = { _ in }) {
        let audioSession = AVAudioSession.sharedInstance()

        if #available(iOS 27.0, *) {
            audioSession.activate { success, error in
                if let error {
                    print(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try audioSession.setActive(true)
                    DispatchQueue.main.async { completion(true) }
                } catch {
                    print(error.localizedDescription)
                    DispatchQueue.main.async { completion(false) }
                }
            }
        }
    }
    
    
    func deactivateSession(completion: @escaping @MainActor @Sendable (Bool) -> Void = { _ in }) {
        let audioSession = AVAudioSession.sharedInstance()

        if #available(iOS 27.0, *) {
            audioSession.deactivate { success, error in
                if let error {
                    print(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try audioSession.setActive(false)
                    DispatchQueue.main.async { completion(true) }
                } catch {
                    print(error.localizedDescription)
                    DispatchQueue.main.async { completion(false) }
                }
            }
        }
    }
    
    func checkPlayerRunning(audioString: String) -> Bool{
        //print ("@@@ player rate \(AlhanPlayer.sharedInstance.player.rate)")
        //print ("$$$ here is the current session mode \(AVAudioSession.sharedInstance().mode)")
        //print ("$$$ here is the current session desc \(AVAudioSession.sharedInstance().description)$$$$$")
        var isRunning = false
        
//        // Pause playlist if running --- used it in PlayButtonTapped
//        if (AlhanPlayer.sharedInstance.queuePlayer.rate == 1.0 ) {
//            print("### PlayList player is on")
//            AlhanPlayer.sharedInstance.queuePlayer.pause()
//        }
        
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
              //  progressBar.value = Float((AlhanPlayer.sharedInstance.player.currentTime().seconds))
            } else
            {
                AlhanPlayer.sharedInstance.player.pause()
            }
        }
        return isRunning
    }
    
    // MARK: file handling
    
    @objc func saveFile(){
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
        
        fileIsLocal = true
        updateToolbar(isPlaying: AlhanPlayer.sharedInstance.isPlaying)
    }

   
    @objc func deleteFile(){
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
        fileIsLocal = false
        updateToolbar(isPlaying: AlhanPlayer.sharedInstance.isPlaying)
        
        
    }
    
    
    
    // MARK: View Functions
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        alignHymnParagraphs()
        updateStanzaBandPositions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        startPlaybackTimeObserver()

        alignedTextWidth = 0
        alignHymnParagraphs()
        HymnTextCoptic.setContentOffset(.zero, animated: false)
        HymnTextEnglish.setContentOffset(.zero, animated: false)
        updateStanzaBandPositions()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HymnDetailViewController.finishedPlaying),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: AlhanPlayer.sharedInstance.player.currentItem
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferredContentSizeChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferredContentSizeChange),
            name: .hymnTextSizeDidChange,
            object: nil
        )
    }

    @objc private func handlePreferredContentSizeChange() {
        configureHymnText()
        alignedTextWidth = 0
        alignHymnParagraphs()
        configureTimeLabel(elapsedTimeLabel, alignment: .right)
        configureTimeLabel(durationTimeLabel, alignment: .left)
        updateColumnLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaybackTimeObserver()

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
        
        deactivateSession { success in
            if success {
                print("AVAudioSession is inactive")
            }
        }
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        print("--- audioPlayerEndInterruption")
        guard
            AVAudioSession.InterruptionOptions(rawValue: UInt(flags)) == .shouldResume
                && interruptedOnPlayback
        else { return }
        activateSession { [weak self] success in
            guard let self, success else { return }
            print("AVAudioSession is Active again")
            interruptedOnPlayback = false
            playButtonTapped()
        }
       
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
