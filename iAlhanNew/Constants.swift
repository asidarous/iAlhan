//
//  Constants.swift
//  iAlhanNew
//
//  Created by Sidarous, Arsani on 10/17/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import Foundation
import UIKit

struct GlobalConstants {

 static let kColor_DarkColor: UIColor = UIColor(red: CGFloat(70/255.0), green: CGFloat(0/255.0), blue: CGFloat(0/255.0), alpha: CGFloat(1.0) )
 static let kColor_GoldColor: UIColor = UIColor(red: CGFloat(255/255.0), green: CGFloat(223/255.0), blue: CGFloat(107/255.0), alpha: CGFloat(1.0) )

}

@MainActor
enum AppAppearance {
    static let creamColor = UIColor(red: 0.97, green: 0.94, blue: 0.84, alpha: 1)
    static let cellCreamColor = UIColor(red: 1.0, green: 0.98, blue: 0.91, alpha: 1)
    static let playerTintColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.10)
    static let playerSurfaceColor = UIColor(
        red: 0.92745,
        green: 0.882,
        blue: 0.819,
        alpha: 1
    )
    static let playerBorderColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.30)
    static let seasonCaptionColor = UIColor(red: 0.55, green: 0.08, blue: 0.1, alpha: 0.85)
    /// Subtle warm tint used to shade every other stanza in the hymn detail reading view,
    /// so the eye can track which Coptic/English lines belong to the same stanza.
    static let stanzaShadeColor = GlobalConstants.kColor_DarkColor.withAlphaComponent(0.06)

    static func copticBaseFont(ofSize size: CGFloat) -> UIFont {
        UIFont(name: "FreeSerifAvvaShenouda", size: size)
            ?? UIFont(name: "COPT", size: size)
            ?? UIFont.systemFont(ofSize: size)
    }

    static func copticFont(ofSize size: CGFloat, relativeTo textStyle: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: textStyle).scaledFont(for: copticBaseFont(ofSize: size))
    }

    // MARK: Arabic-in-Coptic-font handling
    //
    // Some hymn text (hymn_name and hymn_coptic both) has Arabic phrases mixed in,
    // occasionally whole hymns' worth. The Coptic display font has glyphs mapped to
    // Arabic characters, but lacks the contextual joining a properly-shaped Arabic font
    // provides, so those letters render disconnected/isolated instead of Arabic's
    // required connected cursive forms. Anywhere Coptic-font text is shown, route it
    // through `attributedStringHandlingArabic` instead of setting `.text` directly, so
    // Arabic runs get re-fonted to a font that shapes them correctly.

    /// Arabic-script Unicode ranges: the main block, its supplement and extended-A
    /// block, and the two presentation-forms blocks some text sources still use for
    /// pre-composed contextual letter forms.
    private static let arabicCodeUnitRanges: [ClosedRange<UInt16>] = [
        0x0600...0x06FF,
        0x0750...0x077F,
        0x08A0...0x08FF,
        0xFB50...0xFDFF,
        0xFE70...0xFEFF
    ]

    private static func isArabicCodeUnit(_ codeUnit: UInt16) -> Bool {
        arabicCodeUnitRanges.contains { $0.contains(codeUnit) }
    }

    /// Re-fonts the Arabic runs within `range` to a system font that shapes Arabic
    /// correctly (GeezaPro), leaving every other character's existing font attribute
    /// untouched. Text direction and alignment need no separate handling: as long as
    /// the paragraph style involved uses the default `.natural` alignment/writing
    /// direction (true everywhere in this app), TextKit's own Unicode Bidi Algorithm
    /// lays out an Arabic run, or a whole Arabic line, correctly on its own.
    static func applyArabicFontOverride(
        to attributedString: NSMutableAttributedString,
        in range: NSRange,
        pointSize: CGFloat
    ) {
        guard range.length > 0 else { return }
        let arabicFont = UIFont(name: "GeezaPro", size: pointSize) ?? UIFont.systemFont(ofSize: pointSize)
        let nsString = attributedString.string as NSString

        var runStart: Int?
        let end = range.location + range.length
        for index in range.location..<end {
            if isArabicCodeUnit(nsString.character(at: index)) {
                if runStart == nil { runStart = index }
            } else if let start = runStart {
                attributedString.addAttribute(.font, value: arabicFont, range: NSRange(location: start, length: index - start))
                runStart = nil
            }
        }
        if let start = runStart {
            attributedString.addAttribute(.font, value: arabicFont, range: NSRange(location: start, length: end - start))
        }
    }

    /// Builds a `text`-in-`baseFont` attributed string with any Arabic runs re-fonted so
    /// they render correctly. Convenience for the common case of a single label showing
    /// Coptic-font text that might be entirely or partly Arabic (e.g. a hymn's title).
    static func attributedStringHandlingArabic(
        _ text: String,
        baseFont: UIFont,
        extraAttributes: [NSAttributedString.Key: Any] = [:]
    ) -> NSAttributedString {
        var attributes = extraAttributes
        attributes[.font] = baseFont
        let result = NSMutableAttributedString(string: text, attributes: attributes)
        applyArabicFontOverride(
            to: result,
            in: NSRange(location: 0, length: (text as NSString).length),
            pointSize: baseFont.pointSize
        )
        return result
    }

    static func configureCreamBackground(for view: UIView) {
        view.backgroundColor = creamColor
    }

    static func configureNavigationBar(for viewController: UIViewController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = GlobalConstants.kColor_DarkColor
        appearance.titleTextAttributes = [
            .foregroundColor: GlobalConstants.kColor_GoldColor,
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: GlobalConstants.kColor_GoldColor
        ]

        viewController.navigationItem.standardAppearance = appearance
        viewController.navigationItem.scrollEdgeAppearance = appearance
        viewController.navigationItem.compactAppearance = appearance
        viewController.navigationItem.compactScrollEdgeAppearance = appearance
        if #available(iOS 26.0, *) {
            viewController.navigationController?.navigationBar.tintColor = GlobalConstants.kColor_DarkColor
        } else {
            viewController.navigationController?.navigationBar.tintColor = GlobalConstants.kColor_GoldColor
        }
    }

    static func configureRoundNavigationButton(
        _ button: UIButton,
        systemImageName: String,
        accessibilityLabel: String
    ) {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let image = UIImage(
            systemName: systemImageName,
            withConfiguration: symbolConfiguration
        )?.withRenderingMode(.alwaysTemplate)

        var configuration: UIButton.Configuration
        if #available(iOS 26.0, *) {
            configuration = .glass()
        } else {
            configuration = .tinted()
            configuration.baseBackgroundColor = cellCreamColor
        }

        configuration.image = image
        configuration.baseForegroundColor = GlobalConstants.kColor_DarkColor
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: 10,
            bottom: 10,
            trailing: 10
        )

        button.configuration = configuration
        button.tintColor = GlobalConstants.kColor_DarkColor
        button.accessibilityLabel = accessibilityLabel
        button.imageView?.isAccessibilityElement = false
    }

    static func configureTable(_ tableView: UITableView) {
        configureCreamBackground(for: tableView)
        tableView.separatorColor = .separator
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
    }

    static func configureTextField(_ textField: UITextField) {
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.textColor = .label
        textField.tintColor = GlobalConstants.kColor_DarkColor
        textField.layer.cornerRadius = 12
        textField.layer.cornerCurve = .continuous
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.clearButtonMode = .whileEditing
    }

    static func configurePrimaryButton(_ button: UIButton) {
        let title = button.title(for: .normal)
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .large
        configuration.baseBackgroundColor = GlobalConstants.kColor_DarkColor
        configuration.baseForegroundColor = GlobalConstants.kColor_GoldColor
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updatedAttributes = attributes
            updatedAttributes.foregroundColor = GlobalConstants.kColor_GoldColor
            return updatedAttributes
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)
        button.configuration = configuration
        button.setTitleColor(GlobalConstants.kColor_GoldColor, for: .normal)
        button.setTitleColor(GlobalConstants.kColor_GoldColor.withAlphaComponent(0.72), for: .highlighted)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    static func configureSecondaryButton(_ button: UIButton) {
        let title = button.title(for: .normal)
        var configuration = UIButton.Configuration.tinted()
        configuration.title = title
        configuration.cornerStyle = .large
        configuration.baseForegroundColor = GlobalConstants.kColor_DarkColor
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16)
        button.configuration = configuration
        button.setTitleColor(GlobalConstants.kColor_DarkColor, for: .normal)
        button.setTitleColor(GlobalConstants.kColor_DarkColor.withAlphaComponent(0.72), for: .highlighted)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }
}
