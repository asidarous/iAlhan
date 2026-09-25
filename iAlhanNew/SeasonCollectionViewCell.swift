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

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            clipsToBounds = false
            contentView.clipsToBounds = false
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.25
            layer.shadowRadius = 7
            layer.shadowOffset = CGSize(width: 0, height: 3)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: itemImageView.frame,
            cornerRadius: itemImageView.layer.cornerRadius
        ).cgPath
    }
    
    func setSeasonItem(item: SeasonData) {
        itemImageView.image = UIImage(named: item.seasonImage)

        var radius: CGFloat

        if traitCollection.horizontalSizeClass == .compact {
            radius = frame.width * 0.28
            itemImageView.layer.borderWidth = 1
        } else {
            radius = frame.width * 0.22
            itemImageView.layer.borderWidth = 2
        }

        itemImageView.layer.cornerRadius = radius
        itemImageView.clipsToBounds = true
        itemImageView.layer.borderColor = UIColor.white.cgColor
        itemLabel.text = item.title
    }
    

    
}
