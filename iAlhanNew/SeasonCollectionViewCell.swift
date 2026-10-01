//
//  SeasonCollectionViewCell.swift
//  iAlhan
//
//  Created by Sidarous, Arsani on 10/25/16.
//  Copyright © 2016 alhan.org. All rights reserved.
//

import UIKit

class SeasonCollectionViewCell: UICollectionViewCell {

    @IBOutlet var itemLabel: UILabel!
    @IBOutlet var itemImageView: UIImageView!

    // The season artwork ranges from detailed icon paintings to simple flat emblems
    // (e.g. the Feast of the Cross). Filling the whole card with either, edge to edge,
    // made the flat ones read as an oversized logo rather than art. Instead, the source
    // artwork now sits behind a soft blur + gradient scrim as atmosphere, while a
    // smaller, sharp "medallion" copy of the same image floats on top with a gold ring
    // and its own shadow — a treatment that reads as considered regardless of whether
    // the underlying asset is a rich painting or a plain icon.
    private let blurOverlayView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let scrimLayer = CAGradientLayer()
    private let medallionContainer = UIView()
    private let medallionImageView = UIImageView()
    private let captionLabel = UILabel()
    private var medallionWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            clipsToBounds = false
            contentView.clipsToBounds = false
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.12
            layer.shadowRadius = 10
            layer.shadowOffset = CGSize(width: 0, height: 5)

            itemImageView.layer.cornerRadius = 18
            itemImageView.layer.cornerCurve = .continuous
            itemImageView.clipsToBounds = true
            itemImageView.layer.borderWidth = 1
            itemImageView.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor

            configureBackdropBlur()
            configureMedallion()
            configureCaption()

            // The original bottom-pinned pill label is superseded by `captionLabel`
            // above, which reads as a lighter, more modern caption under the medallion.
            itemLabel.isHidden = true
        }
    }

    private func configureBackdropBlur() {
        blurOverlayView.layer.cornerRadius = 18
        blurOverlayView.layer.cornerCurve = .continuous
        blurOverlayView.clipsToBounds = true
        blurOverlayView.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(blurOverlayView, aboveSubview: itemImageView)
        NSLayoutConstraint.activate([
            blurOverlayView.leadingAnchor.constraint(equalTo: itemImageView.leadingAnchor),
            blurOverlayView.trailingAnchor.constraint(equalTo: itemImageView.trailingAnchor),
            blurOverlayView.topAnchor.constraint(equalTo: itemImageView.topAnchor),
            blurOverlayView.bottomAnchor.constraint(equalTo: itemImageView.bottomAnchor)
        ])

        // A gentle top-to-bottom scrim over the blur, deep enough at the bottom to keep
        // the caption legible over any artwork without needing an opaque bar.
        scrimLayer.colors = [
            GlobalConstants.kColor_DarkColor.withAlphaComponent(0.10).cgColor,
            GlobalConstants.kColor_DarkColor.withAlphaComponent(0.80).cgColor
        ]
        scrimLayer.locations = [0, 1]
        blurOverlayView.contentView.layer.addSublayer(scrimLayer)
    }

    private func configureMedallion() {
        medallionContainer.backgroundColor = .clear
        medallionContainer.layer.shadowColor = UIColor.black.cgColor
        medallionContainer.layer.shadowOpacity = 0.35
        medallionContainer.layer.shadowRadius = 6
        medallionContainer.layer.shadowOffset = CGSize(width: 0, height: 3)
        medallionContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(medallionContainer, aboveSubview: blurOverlayView)

        medallionImageView.contentMode = .scaleAspectFill
        medallionImageView.clipsToBounds = true
        medallionImageView.layer.borderWidth = 2
        medallionImageView.layer.borderColor = GlobalConstants.kColor_GoldColor.withAlphaComponent(0.85).cgColor
        medallionImageView.translatesAutoresizingMaskIntoConstraints = false
        medallionContainer.addSubview(medallionImageView)
        NSLayoutConstraint.activate([
            medallionImageView.leadingAnchor.constraint(equalTo: medallionContainer.leadingAnchor),
            medallionImageView.trailingAnchor.constraint(equalTo: medallionContainer.trailingAnchor),
            medallionImageView.topAnchor.constraint(equalTo: medallionContainer.topAnchor),
            medallionImageView.bottomAnchor.constraint(equalTo: medallionContainer.bottomAnchor)
        ])

        // Sized in `layoutSubviews` as a fraction of the card's *shorter* dimension, so
        // it stays proportionate whether the cell is a short, wide hero card or a
        // roughly square grid card.
        medallionWidthConstraint = medallionContainer.widthAnchor.constraint(equalToConstant: 80)
        NSLayoutConstraint.activate([
            medallionContainer.centerXAnchor.constraint(equalTo: itemImageView.centerXAnchor),
            medallionContainer.centerYAnchor.constraint(equalTo: itemImageView.centerYAnchor, constant: -8),
            medallionWidthConstraint,
            medallionContainer.heightAnchor.constraint(equalTo: medallionContainer.widthAnchor)
        ])
    }

    private func configureCaption() {
        captionLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 2
        captionLabel.textColor = GlobalConstants.kColor_GoldColor
        captionLabel.layer.shadowColor = UIColor.black.cgColor
        captionLabel.layer.shadowOpacity = 0.6
        captionLabel.layer.shadowRadius = 3
        captionLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(captionLabel, aboveSubview: medallionContainer)
        NSLayoutConstraint.activate([
            captionLabel.leadingAnchor.constraint(equalTo: itemImageView.leadingAnchor, constant: 10),
            captionLabel.trailingAnchor.constraint(equalTo: itemImageView.trailingAnchor, constant: -10),
            captionLabel.topAnchor.constraint(equalTo: medallionContainer.bottomAnchor, constant: 8),
            captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: itemImageView.bottomAnchor, constant: -10)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: itemImageView.frame,
            cornerRadius: itemImageView.layer.cornerRadius
        ).cgPath

        let shorterSide = min(itemImageView.bounds.width, itemImageView.bounds.height)
        medallionWidthConstraint.constant = max(56, shorterSide * 0.48)
        medallionContainer.layer.cornerRadius = medallionContainer.bounds.width / 2
        medallionImageView.layer.cornerRadius = medallionImageView.bounds.width / 2
        scrimLayer.frame = blurOverlayView.bounds
    }

    func setSeasonItem(item: SeasonData) {
        let image = UIImage(named: item.seasonImage)
        itemImageView.image = image
        itemImageView.clipsToBounds = true
        medallionImageView.image = image
        captionLabel.text = item.title
        itemLabel.text = item.title
        accessibilityLabel = item.title
    }
}
