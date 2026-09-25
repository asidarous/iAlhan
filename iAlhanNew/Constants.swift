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
        viewController.navigationController?.navigationBar.tintColor = GlobalConstants.kColor_GoldColor
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
}
