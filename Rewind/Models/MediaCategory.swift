import Foundation
import Photos

nonisolated enum MediaCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case photos
    case screenshots
    case videos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photos: "Photos"
        case .screenshots: "Screenshots"
        case .videos: "Videos"
        }
    }

    var emptyCopy: String {
        switch self {
        case .photos: "No photos here."
        case .screenshots: "No screenshots here."
        case .videos: "No videos here."
        }
    }

    /// Screenshots commit fastest; videos need a slightly longer drag.
    var commitThreshold: CGFloat {
        switch self {
        case .photos: 0.30
        case .screenshots: 0.22
        case .videos: 0.345
        }
    }

    var fetchPredicate: NSPredicate {
        switch self {
        case .photos:
            NSPredicate(
                format: "mediaType == %d AND ((mediaSubtype & %d) == 0)",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
        case .screenshots:
            NSPredicate(
                format: "(mediaSubtype & %d) != 0",
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )
        case .videos:
            NSPredicate(
                format: "mediaType == %d",
                PHAssetMediaType.video.rawValue
            )
        }
    }
}
