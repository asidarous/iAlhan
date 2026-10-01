import UIKit

extension Notification.Name {
    static let hymnTextSizeDidChange = Notification.Name("hymnTextSizeDidChange")
}

enum HymnTextSize: Int, CaseIterable {
    case smaller
    case standard
    case larger
    case largest

    var title: String {
        switch self {
        case .smaller: return "Smaller"
        case .standard: return "Standard"
        case .larger: return "Larger"
        case .largest: return "Largest"
        }
    }

    var scale: CGFloat {
        switch self {
        case .smaller: return 0.85
        case .standard: return 1
        case .larger: return 1.2
        case .largest: return 1.4
        }
    }
}

@MainActor
enum ReadingPreferences {
    private static let hymnTextSizeKey = "hymnTextSize"

    static var hymnTextSize: HymnTextSize {
        get {
            HymnTextSize(
                rawValue: UserDefaults.standard.integer(forKey: hymnTextSizeKey)
            ) ?? .standard
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: hymnTextSizeKey)
            NotificationCenter.default.post(name: .hymnTextSizeDidChange, object: nil)
        }
    }

    static func scaledFont(
        baseFont: UIFont,
        relativeTo textStyle: UIFont.TextStyle,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        let preferredSize = UIFontMetrics(forTextStyle: textStyle).scaledValue(
            for: baseFont.pointSize,
            compatibleWith: traitCollection
        )
        return baseFont.withSize(preferredSize * hymnTextSize.scale)
    }
}
