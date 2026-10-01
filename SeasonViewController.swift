//
//  SeasonViewController.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/7/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit
import CoreImage

struct SeasonData {
    var title: String!
    var seasonImage: String!
    var seasonID: Int!

}

private extension UIImage {
    /// A rough average color of the whole image, computed by downsampling it to a
    /// single pixel with Core Image's area-average filter — the standard, cheap way to
    /// get a representative color for tinting UI around a piece of artwork.
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extent = inputImage.extent
        let extentVector = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: extentVector
        ]), let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }
}

private extension UIColor {
    /// Linearly interpolates toward `other`; `fraction` 0 is `self`, 1 is `other`.
    func blended(with other: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 + (r2 - r1) * fraction,
            green: g1 + (g2 - g1) * fraction,
            blue: b1 + (b2 - b1) * fraction,
            alpha: a1 + (a2 - a1) * fraction
        )
    }
}



class SeasonViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet var collectionView: UICollectionView!
    
    var seasonImages: [UIImage]!
    var seasonLabels: [UILabel]!
    var seasonsData: [SeasonData]!
    
    var iPath: IndexPath!
    
    var iSize: CGSize!
    var coverLayer: CALayer!
    private let backgroundOverlayView = UIView()
    private let backgroundGradientLayer = CAGradientLayer()
    private var searchText = ""
    private var hymnSearchResults = [EventHymns]()
    private var currentSeason: SeasonData?
    private var upcomingSeason: SeasonData?

    private enum Section: Int, CaseIterable {
        case masthead
        case current
        case upcoming
        case browse
    }

    private var browsedSeasons: [SeasonData] {
        let featuredTitles = Set([currentSeason?.title, upcomingSeason?.title].compactMap { $0 })
        return seasonsData.filter { !featuredTitles.contains($0.title) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // check version only if connected to Internet
        //if Reachability.isConnectedToNetwork(){
        //    update = CheckVersion()
        //}
        
        AppAppearance.configureNavigationBar(for: self)
        configureBackground()
        collectionView.backgroundColor = .clear
        collectionView.register(
            SeasonHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SeasonHeaderView.reuseIdentifier
        )
        collectionView.register(
            HymnSearchResultCell.self,
            forCellWithReuseIdentifier: HymnSearchResultCell.reuseIdentifier
        )
        collectionView.register(
            SeasonSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SeasonSectionHeaderView.reuseIdentifier
        )
        coverLayer = CALayer()
        
        
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact
            
            iSize = CGSize(width: collectionView.frame.width * 0.28, height: collectionView.frame.width * 0.28)

            
        } else {
            // Regular
            iSize = CGSize(width: collectionView.frame.width * 0.22, height: collectionView.frame.width * 0.22)
            
        }
        
        removeLegacySwipeInstruction()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        updateUI()
        
        
        
        
        
    }

    /// Called on every keystroke purely to keep an emptied field feeling instant: no
    /// database query runs here. The actual search only runs when the user taps the
    /// "Search" key, in `runSearch(for:isEnglishInput:)` below.
    private func clearResultsIfSearchTextIsEmpty(_ rawText: String) {
        let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText = trimmedText
        guard trimmedText.isEmpty else { return }
        hymnSearchResults = []
        collectionView.reloadSections(IndexSet(integer: Section.browse.rawValue))
    }

    /// Runs the hymn search once, when the user explicitly taps "Search" on either
    /// keyboard (the custom Coptic keyboard's own Search key, or the system keyboard's
    /// search/return key while typing English). Which column is searched follows which
    /// keyboard was active: Coptic input can only ever match the Coptic hymn name, and
    /// English input can only ever match the short English description.
    private func runSearch(for rawText: String, isEnglishInput: Bool) {
        let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText = trimmedText

        guard !trimmedText.isEmpty else {
            hymnSearchResults = []
            collectionView.reloadSections(IndexSet(integer: Section.browse.rawValue))
            return
        }

        hymnSearchResults = DBManager.shared.searchHymns(
            matching: trimmedText,
            field: isEnglishInput ? .englishDescription : .copticName
        )
        collectionView.reloadSections(IndexSet(integer: Section.browse.rawValue))
    }

    private func configureBackground() {
        view.backgroundColor = GlobalConstants.kColor_DarkColor

        backgroundOverlayView.translatesAutoresizingMaskIntoConstraints = false
        backgroundOverlayView.isUserInteractionEnabled = false
        backgroundOverlayView.accessibilityElementsHidden = true
        view.insertSubview(backgroundOverlayView, belowSubview: collectionView)

        backgroundGradientLayer.locations = [0, 0.3, 1]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundOverlayView.layer.addSublayer(backgroundGradientLayer)
        applyBackgroundGlow(for: nil)

        NSLayoutConstraint.activate([
            backgroundOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = backgroundOverlayView.bounds
    }

    /// Tints the top of the screen's background with a muted sample of the featured
    /// season's own artwork, so the plain burgundy backdrop behind the masthead and the
    /// "Current Season" card's own blurred-artwork background read as one continuous
    /// surface rather than a flat color butting up against a differently-colored card.
    /// Fades back to the normal burgundy by the time the "Upcoming Season"/"Browse by
    /// Season" sections start, and further to near-black at the very bottom, matching
    /// the depth the gradient already had.
    private func applyBackgroundGlow(for season: SeasonData?) {
        let nearBlack = UIColor(red: 0.12, green: 0.10, blue: 0.10, alpha: 1)
        let glow = season
            .flatMap { UIImage(named: $0.seasonImage) }
            .flatMap { $0.averageColor() }
            .map { $0.blended(with: GlobalConstants.kColor_DarkColor, fraction: 0.5) }
            ?? GlobalConstants.kColor_DarkColor

        backgroundGradientLayer.colors = [
            glow.cgColor,
            GlobalConstants.kColor_DarkColor.cgColor,
            nearBlack.cgColor
        ]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        // if DB updated
        if update{
            
            showUpdateAlertButton(in: self)
            update=false
        }
    }

    func updateUI() {
        seasonsData = DBManager.shared.loadSeasons()
        currentSeason = seasonData(
            titled: CopticLiturgicalCalendar.currentSeasonTitle()
        )
        upcomingSeason = seasonData(
            titled: CopticLiturgicalCalendar.upcomingSeasonTitle()
        )
        // Blend against whichever banner card actually renders at the top of the
        // screen — "Current Season" when there is one, otherwise "Upcoming Season",
        // since on most days there's no active named season at all (see
        // CopticLiturgicalCalendar's "ordinary time" gaps).
        applyBackgroundGlow(for: currentSeason ?? upcomingSeason)
        collectionView.reloadData()
    }

    private func seasonData(titled title: String?) -> SeasonData? {
        guard let title else { return nil }
        return seasonsData.first(where: { $0.title == title })
    }
    
    // MARK: - Target/Action
    
    
    // MARK: - Collection View
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .masthead:
            return 0
        case .current:
            return currentSeason == nil ? 0 : 1
        case .upcoming:
            return upcomingSeason == nil ? 0 : 1
        case .browse:
            return searchText.isEmpty ? browsedSeasons.count : hymnSearchResults.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == Section.browse.rawValue, !searchText.isEmpty {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HymnSearchResultCell.reuseIdentifier,
                for: indexPath
            ) as! HymnSearchResultCell
            cell.configure(with: hymnSearchResults[indexPath.item])
            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SeasonCollectionViewCell",
            for: indexPath
        ) as! SeasonCollectionViewCell
        cell.setSeasonItem(item: season(at: indexPath))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == Section.browse.rawValue, !searchText.isEmpty {
            showHymnDetail(hymnSearchResults[indexPath.item])
            return
        }

        let season = season(at: indexPath)
        performSegue(
            withIdentifier: "Show Season Detail",
            sender: [season.seasonID!, season.title as Any] as [Any]
        )
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == Section.current.rawValue ||
            indexPath.section == Section.upcoming.rawValue {
            return CGSize(width: collectionView.bounds.width - 16, height: 165)
        }
        if !searchText.isEmpty {
            return CGSize(width: collectionView.bounds.width - 8, height: 72)
        }

        let columns: CGFloat = 3
        let horizontalInsets: CGFloat = 16
        let totalSpacing = (columns - 1) * 10
        let width = floor((collectionView.bounds.width - horizontalInsets - totalSpacing) / columns)
        return CGSize(width: width, height: width + 38)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard let section = Section(rawValue: section) else { return .zero }

        let height: CGFloat
        switch section {
        case .masthead:
            // The masthead artwork is sized to its own aspect ratio (see
            // SeasonHeaderView's layout) rather than a fixed height, since the current
            // artwork is proportioned very differently from whatever preceded it. This
            // mirrors that same math so the collection view reserves exactly the space
            // the header will actually use.
            let availableWidth = collectionView.bounds.width - SeasonHeaderView.mastheadHorizontalMargin * 2
            let imageHeight = availableWidth * SeasonHeaderView.mastheadAspectRatio
            height = imageHeight + SeasonHeaderView.mastheadChromeHeight
        case .current:
            height = currentSeason == nil ? 0 : 48
        case .upcoming, .browse:
            height = 48
        }
        return CGSize(width: collectionView.frame.width, height: height)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if indexPath.section == Section.masthead.rawValue {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SeasonHeaderView.reuseIdentifier,
                for: indexPath
            ) as! SeasonHeaderView
            header.searchText = searchText
            header.onSearchTextChanged = { [weak self] text in
                self?.clearResultsIfSearchTextIsEmpty(text)
            }
            header.onSearchRequested = { [weak self] text, isEnglishInput in
                self?.runSearch(for: text, isEnglishInput: isEnglishInput)
            }
            return header
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SeasonSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! SeasonSectionHeaderView

        let title: String
        switch Section(rawValue: indexPath.section) {
        case .current:
            title = "Current Season"
        case .upcoming:
            title = "Upcoming Season"
        case .browse:
            title = searchText.isEmpty ? "Browse by Season" : "Hymn Results"
        case .masthead, .none:
            title = ""
        }
        header.configure(title: title)
        return header
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard let section = Section(rawValue: section) else { return .zero }

        switch section {
        case .masthead:
            return .zero
        case .current:
            return currentSeason == nil
                ? .zero
                : UIEdgeInsets(top: 0, left: 8, bottom: 12, right: 8)
        case .upcoming:
            return UIEdgeInsets(top: 0, left: 8, bottom: 12, right: 8)
        case .browse:
            return UIEdgeInsets(top: 0, left: 8, bottom: 24, right: 8)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        section == Section.browse.rawValue ? 12 : 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        section == Section.browse.rawValue ? 10 : 14
    }

    private func showHymnDetail(_ hymn: EventHymns) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailViewController = storyboard.instantiateViewController(
            withIdentifier: "HymnDetailViewController"
        ) as? HymnDetailViewController else { return }
        detailViewController.hymnDetail = [hymn]
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    private func season(at indexPath: IndexPath) -> SeasonData {
        switch Section(rawValue: indexPath.section) {
        case .current:
            guard let currentSeason else {
                preconditionFailure("The current section has no season item")
            }
            return currentSeason
        case .upcoming:
            guard let upcomingSeason else {
                preconditionFailure("The upcoming section has no season item")
            }
            return upcomingSeason
        case .browse:
            return browsedSeasons[indexPath.item]
        case .masthead, .none:
            preconditionFailure("The masthead section does not contain season items")
        }
    }

    // MARK:- UICollectionViewDelegate Methods

    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        coverLayer.frame = CGRect(origin: collectionView.frame.origin, size: iSize)
        coverLayer.backgroundColor = UIColor.black.cgColor
        coverLayer.opacity = 0.1
        cell?.layer.addSublayer(coverLayer)
        
            
            //.backgroundColor = UIColor.red
    }
    
    // change background color back when user releases touch
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = .clear
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            switch identifier
            {
                case "Show Season Detail":
                    //print ("I'm here")
                    let seasonDetailVC = segue.destination as! SeasonDetailViewController
                    //print (seasonDetailVC.detailTextView)
                    //var point:CGPoint = sender. .locationInView(collectionView)
                    //print("#### \(self.collectionView.indexPathForItem(at: point))")

                    let data = sender as! NSArray
                    //print (detailImageView)da
                    //if let index = seasonImages.index(of: detailImageView)
                    //{
                    
                        let seasonID = data[0]
                        let hymnArray = DBManager.shared.loadSeasonHymns(WithID: seasonID as! Int)
                        
                        //print ("Print from within SeasonVC \(hymnArray)")
                        seasonDetailVC.labelText = data[1] as? String
                        seasonDetailVC.seasonHymns = hymnArray
                
                    //}
               
            
                
                default:
                    break
            
            
            }
        }
    }
    
    private func removeLegacySwipeInstruction() {
        func hideInstruction(in view: UIView) {
            if let label = view as? UILabel,
               label.text?.contains("Swipe left") == true {
                label.superview?.isHidden = true
                return
            }
            view.subviews.forEach(hideInstruction)
        }
        hideInstruction(in: view)
    }
}

/// Liturgical masthead artwork above the season grid, followed by the hymn search field.
private final class SeasonHeaderView: UICollectionReusableView, UISearchBarDelegate {
    static let reuseIdentifier = "SeasonHeaderView"

    /// The masthead artwork's *visible content's* height-to-width ratio, not the full
    /// canvas's. The source PNG is 2170x725, but the gold lettering only occupies a
    /// ~294px-tall band in the middle — measured directly from the image's alpha
    /// channel — with transparent padding above and below. Sizing the box from the
    /// full canvas (725/2170 ≈ 0.334) reserved roughly 2.4x more height than the art
    /// needs, which is what made the masthead feel oversized. This ratio (with a small
    /// safety margin over the measured 294/2170 ≈ 0.136, so anti-aliased edges and
    /// ornament tips aren't clipped) is paired with `.scaleAspectFill` below, which
    /// fills the box's full width and crops away most of the top/bottom padding rather
    /// than leaving it visible as empty space.
    static let mastheadAspectRatio: CGFloat = 0.15
    static let mastheadHorizontalMargin: CGFloat = 12
    /// Everything in the header besides the masthead image itself: the gap, the gold
    /// separator, the gap before the search field, the search field's own height, and
    /// the bottom margin. Used by SeasonViewController to reserve the right total
    /// header height alongside this view's own Auto Layout constraints below.
    static let mastheadChromeHeight: CGFloat = 65

    private let mastheadImageView = UIImageView()
    private let separatorView = UIView()
    private let separatorOrnament = UIView()
    private let searchBar = UISearchBar()
    private var isEnglishInputMode = false
    private lazy var copticKeyboardView = CopticKeyboardView(
        onCharacter: { [weak self] character in
            guard let self else { return }
            self.searchBar.searchTextField.insertText(character)
            self.onSearchTextChanged?(self.searchBar.text ?? "")
        },
        onDelete: { [weak self] in
            guard let self else { return }
            self.searchBar.searchTextField.deleteBackward()
            self.onSearchTextChanged?(self.searchBar.text ?? "")
        },
        onSearch: { [weak self] in
            guard let self else { return }
            self.searchBar.resignFirstResponder()
            self.onSearchRequested?(self.searchBar.text ?? "", false)
        },
        onToggleLanguage: { [weak self] in
            self?.setEnglishInputMode(true)
        }
    )
    private lazy var switchToCopticAccessory = makeSwitchToCopticAccessory()
    /// Fired on every keystroke; used only to clear results instantly when the field is
    /// emptied. Does not trigger a database search — see `onSearchRequested`.
    var onSearchTextChanged: ((String) -> Void)?
    /// Fired only when the user taps "Search" on either keyboard. The second parameter
    /// is `true` when the system (English) keyboard was active, `false` for Coptic.
    var onSearchRequested: ((String, Bool) -> Void)?
    var searchText: String {
        get { searchBar.text ?? "" }
        set { searchBar.text = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isAccessibilityElement = false
        accessibilityElementsHidden = false

        // This artwork (unlike what preceded it) has a genuinely transparent
        // background, so the screen's own gradient already shows through cleanly
        // around the lettering with no backdrop or edge fade needed.
        mastheadImageView.image = UIImage(named: "SeasonMasthead")
        // Fill (not fit): the box below is deliberately shorter than the full image's
        // own aspect ratio, so aspectFill scales to match the box's width and crops the
        // excess transparent padding off the top and bottom rather than shrinking the
        // whole image down to fit inside a taller box.
        mastheadImageView.contentMode = .scaleAspectFill
        mastheadImageView.clipsToBounds = true
        mastheadImageView.isAccessibilityElement = true
        mastheadImageView.accessibilityLabel = "iAlhan Coptic hymns"
        mastheadImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mastheadImageView)

        separatorView.backgroundColor = GlobalConstants.kColor_GoldColor.withAlphaComponent(0.42)
        separatorOrnament.backgroundColor = GlobalConstants.kColor_GoldColor.withAlphaComponent(0.72)
        separatorOrnament.layer.cornerRadius = 1
        separatorOrnament.transform = CGAffineTransform(rotationAngle: .pi / 4)

        searchBar.delegate = self
        searchBar.placeholder = "Search Coptic hymn name"
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = GlobalConstants.kColor_GoldColor
        searchBar.searchTextField.backgroundColor = AppAppearance.cellCreamColor
        searchBar.searchTextField.textColor = GlobalConstants.kColor_DarkColor
        let searchFont = AppAppearance.copticFont(ofSize: 18, relativeTo: .body)
        let placeholderColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.58)
        searchBar.searchTextField.font = searchFont
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search Coptic hymn name",
            attributes: [
                .font: searchFont,
                .foregroundColor: placeholderColor
            ]
        )
        searchBar.searchTextField.leftView?.tintColor = placeholderColor
        searchBar.searchTextField.clearButtonMode = .whileEditing
        searchBar.searchTextField.accessibilityLabel = "Search hymns"
        searchBar.searchTextField.inputView = copticKeyboardView

        [separatorView, separatorOrnament, searchBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            mastheadImageView.topAnchor.constraint(equalTo: topAnchor),
            mastheadImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.mastheadHorizontalMargin),
            mastheadImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.mastheadHorizontalMargin),
            mastheadImageView.heightAnchor.constraint(
                equalTo: mastheadImageView.widthAnchor,
                multiplier: Self.mastheadAspectRatio
            ),

            separatorView.topAnchor.constraint(equalTo: mastheadImageView.bottomAnchor, constant: 3),
            separatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 76),
            separatorView.heightAnchor.constraint(equalToConstant: 1),

            separatorOrnament.centerXAnchor.constraint(equalTo: separatorView.centerXAnchor),
            separatorOrnament.centerYAnchor.constraint(equalTo: separatorView.centerYAnchor),
            separatorOrnament.widthAnchor.constraint(equalToConstant: 6),
            separatorOrnament.heightAnchor.constraint(equalToConstant: 6),

            searchBar.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            searchBar.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4)
        ])
    }

    private func makeWordmark() -> NSAttributedString {
        let metrics = UIFontMetrics(forTextStyle: .title1)
        let alhanDescriptor = UIFont.systemFont(ofSize: 26, weight: .semibold)
            .fontDescriptor
            .withDesign(.serif)
            ?? UIFont.systemFont(ofSize: 26, weight: .semibold).fontDescriptor
        let alhanFont = metrics.scaledFont(for: UIFont(descriptor: alhanDescriptor, size: 26))

        let italicDescriptor = alhanDescriptor.withSymbolicTraits(.traitItalic) ?? alhanDescriptor
        let italicFont = metrics.scaledFont(for: UIFont(descriptor: italicDescriptor, size: 23))

        // Deep, soft-edged dark shadow cast upward from each glyph, as though the
        // letterforms are grooves cut into the glass with light falling from above:
        // the near (upper) wall of each groove falls into shadow. Strong enough on its
        // own to read as depth rather than a faint outline.
        let engravedShadow = NSShadow()
        engravedShadow.shadowColor = UIColor.black.withAlphaComponent(0.85)
        engravedShadow.shadowOffset = CGSize(width: 0, height: -1.6)
        engravedShadow.shadowBlurRadius = 2.2

        // A muted, slightly cool gray rather than the app's usual gold — the fill reads
        // as the glass's own material showing through a carved void, not as painted
        // text, leaving the shadow/highlight pair to carry the sense of depth.
        let wordmark = NSMutableAttributedString(
            string: "i",
            attributes: [
                .font: italicFont,
                .foregroundColor: UIColor(white: 0.55, alpha: 0.88),
                .shadow: engravedShadow,
                .baselineOffset: 1
            ]
        )
        wordmark.append(
            NSAttributedString(
                string: "Alhan",
                attributes: [
                    .font: alhanFont,
                    .foregroundColor: UIColor(white: 0.68, alpha: 0.9),
                    .shadow: engravedShadow,
                    .kern: 1.1
                ]
            )
        )
        return wordmark
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        onSearchTextChanged?(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        onSearchRequested?(searchBar.text ?? "", isEnglishInputMode)
    }

    /// Swaps the search field between the custom Coptic keyboard (Ava Shenouda glyphs)
    /// and the system keyboard for typing an English hymn name. A small accessory bar
    /// stays pinned above the system keyboard so the user can switch back.
    private func setEnglishInputMode(_ enabled: Bool) {
        guard isEnglishInputMode != enabled else { return }
        isEnglishInputMode = enabled

        let fieldFont = enabled
            ? UIFont.preferredFont(forTextStyle: .body)
            : AppAppearance.copticFont(ofSize: 18, relativeTo: .body)
        let placeholder = enabled ? "Search English hymn description" : "Search Coptic hymn name"
        searchBar.searchTextField.font = fieldFont
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: fieldFont,
                .foregroundColor: GlobalConstants.kColor_DarkColor.withAlphaComponent(0.58)
            ]
        )
        searchBar.searchTextField.inputView = enabled ? nil : copticKeyboardView
        searchBar.searchTextField.inputAccessoryView = enabled ? switchToCopticAccessory : nil

        if searchBar.searchTextField.isFirstResponder {
            searchBar.searchTextField.reloadInputViews()
        }
    }

    @objc private func switchToCopticTapped() {
        setEnglishInputMode(false)
    }

    private func makeSwitchToCopticAccessory() -> UIView {
        let bar = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        bar.backgroundColor = AppAppearance.cellCreamColor
        bar.autoresizingMask = [.flexibleWidth]

        let hairline = UIView()
        hairline.backgroundColor = AppAppearance.playerBorderColor
        hairline.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(hairline)

        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.gray()
        configuration.title = "ⲁⲃⲅ  Coptic Keyboard"
        configuration.baseForegroundColor = GlobalConstants.kColor_DarkColor
        configuration.baseBackgroundColor = AppAppearance.cellCreamColor
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.accessibilityLabel = "Switch to Coptic keyboard"
        button.addTarget(self, action: #selector(switchToCopticTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(button)

        NSLayoutConstraint.activate([
            hairline.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            hairline.topAnchor.constraint(equalTo: bar.topAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 1),

            button.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -12),
            button.centerYAnchor.constraint(equalTo: bar.centerYAnchor)
        ])
        return bar
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class CopticKeyboardView: UIInputView {
    private let onCharacter: (String) -> Void
    private let onDelete: () -> Void
    private let onSearch: () -> Void
    private let onToggleLanguage: () -> Void

    init(
        onCharacter: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onSearch: @escaping () -> Void,
        onToggleLanguage: @escaping () -> Void
    ) {
        self.onCharacter = onCharacter
        self.onDelete = onDelete
        self.onSearch = onSearch
        self.onToggleLanguage = onToggleLanguage
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 270), inputViewStyle: .keyboard)
        allowsSelfSizing = true
        configureKeys()
    }

    private func configureKeys() {
        let rows = [
            ["ⲁ", "ⲃ", "ⲅ", "ⲇ", "ⲉ", "ⲋ", "ⲍ", "ⲏ", "ⲑ"],
            ["ⲓ", "ⲕ", "ⲗ", "ⲙ", "ⲛ", "ⲝ", "ⲟ", "ⲡ"],
            ["ⲣ", "ⲥ", "ⲧ", "ⲩ", "ⲫ", "ⲭ", "ⲯ", "ⲱ"],
            ["ϣ", "ϥ", "ϧ", "ϩ", "ϫ", "ϭ", "ϯ"]
        ]

        let keyboardStack = UIStackView()
        keyboardStack.translatesAutoresizingMaskIntoConstraints = false
        keyboardStack.axis = .vertical
        keyboardStack.spacing = 6
        keyboardStack.isLayoutMarginsRelativeArrangement = true
        keyboardStack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 6,
            bottom: 8,
            trailing: 6
        )

        for rowCharacters in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 5
            for character in rowCharacters {
                row.addArrangedSubview(makeKey(title: character, action: #selector(characterTapped(_:))))
            }
            keyboardStack.addArrangedSubview(row)
        }

        let actions = UIStackView()
        actions.axis = .horizontal
        actions.spacing = 6
        let toggleLanguageButton = makeKey(title: "EN", action: #selector(toggleLanguageTapped))
        toggleLanguageButton.accessibilityLabel = "Switch to English keyboard"
        let deleteButton = makeKey(title: "⌫", action: #selector(deleteTapped))
        let spaceButton = makeKey(title: "space", action: #selector(spaceTapped))
        let searchButton = makeKey(title: "Search", action: #selector(searchTapped), prominent: true)
        actions.addArrangedSubview(toggleLanguageButton)
        actions.addArrangedSubview(deleteButton)
        actions.addArrangedSubview(spaceButton)
        actions.addArrangedSubview(searchButton)
        toggleLanguageButton.widthAnchor.constraint(equalTo: actions.widthAnchor, multiplier: 0.16).isActive = true
        deleteButton.widthAnchor.constraint(equalTo: actions.widthAnchor, multiplier: 0.16).isActive = true
        searchButton.widthAnchor.constraint(equalTo: actions.widthAnchor, multiplier: 0.22).isActive = true
        keyboardStack.addArrangedSubview(actions)

        addSubview(keyboardStack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 270),
            keyboardStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardStack.topAnchor.constraint(equalTo: topAnchor),
            keyboardStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeKey(title: String, action: Selector, prominent: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = prominent ? UIButton.Configuration.filled() : UIButton.Configuration.gray()
        configuration.title = title
        configuration.cornerStyle = .medium
        configuration.baseForegroundColor = prominent ? .white : GlobalConstants.kColor_DarkColor
        configuration.baseBackgroundColor = prominent
            ? GlobalConstants.kColor_DarkColor
            : AppAppearance.cellCreamColor
        button.configuration = configuration
        button.titleLabel?.font = title.count == 1
            ? AppAppearance.copticFont(ofSize: 20, relativeTo: .title3)
            : UIFont.systemFont(ofSize: 16, weight: .medium)
        button.accessibilityLabel = title == "⌫" ? "Delete" : title
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func characterTapped(_ sender: UIButton) {
        guard let character = sender.configuration?.title else { return }
        onCharacter(character)
    }

    @objc private func deleteTapped() {
        onDelete()
    }

    @objc private func spaceTapped() {
        onCharacter(" ")
    }

    @objc private func searchTapped() {
        onSearch()
    }

    @objc private func toggleLanguageTapped() {
        onToggleLanguage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class HymnSearchResultCell: UICollectionViewCell {
    static let reuseIdentifier = "HymnSearchResultCell"
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = AppAppearance.cellCreamColor
        contentView.layer.cornerRadius = 14
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = AppAppearance.playerBorderColor.cgColor

        titleLabel.font = AppAppearance.copticFont(ofSize: 18, relativeTo: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = GlobalConstants.kColor_DarkColor
        titleLabel.lineBreakMode = .byTruncatingTail

        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.textColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.72)
        descriptionLabel.lineBreakMode = .byTruncatingTail

        let labels = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        labels.translatesAutoresizingMaskIntoConstraints = false
        labels.axis = .vertical
        labels.spacing = 3
        contentView.addSubview(labels)

        let disclosure = UIImageView(image: UIImage(systemName: "chevron.right"))
        disclosure.translatesAutoresizingMaskIntoConstraints = false
        disclosure.tintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.55)
        disclosure.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(disclosure)

        NSLayoutConstraint.activate([
            labels.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            labels.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labels.trailingAnchor.constraint(equalTo: disclosure.leadingAnchor, constant: -10),
            disclosure.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            disclosure.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with hymn: EventHymns) {
        titleLabel.text = hymn.hymnName
        descriptionLabel.text = hymn.hymnDescription
        accessibilityLabel = [hymn.hymnName, hymn.hymnDescription]
            .compactMap { $0 }
            .joined(separator: ", ")
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SeasonSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SeasonSectionHeaderView"
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Browse by Season"
        titleLabel.textColor = GlobalConstants.kColor_GoldColor
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
