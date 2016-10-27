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
    
    func setSeasonItem(item: SeasonData) {
        itemImageView.image = UIImage(named: item.seasonImage)
       
        var radius: CGFloat
        
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact) {
            // Compact
            radius = CGFloat(self.frame.width * 0.28 )
        } else {
            // Regular
            radius = CGFloat(self.frame.width * 0.22 )
        }
        
        print("RRRRRRR \(radius)")
        itemImageView.layer.cornerRadius = radius
        itemImageView.clipsToBounds = true
        
        // MARK: Label
        itemLabel.text = item.title
        
    }
    
}
