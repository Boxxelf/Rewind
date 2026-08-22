import CoreImage
import Foundation
import Photos
import UIKit
import Vision

nonisolated enum ScreenshotKind: String, Sendable {
    case receipt
    case chat
    case webpage
    case ticket
    case unknown

    var title: String {
        switch self {
        case .receipt: "Receipt"
        case .chat: "Chat"
        case .webpage: "Webpage"
        case .ticket: "Ticket"
        case .unknown: "Screenshot"
        }
    }
}

enum MediaAssist {
    nonisolated static func classifyScreenshot(asset: PHAsset) async -> ScreenshotKind {
        guard let image = await thumbnail(for: asset, side: 800) else { return .unknown }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        try? handler.perform([request])
        let text = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
            .lowercased()
        if text.contains("total") || text.contains("visa") || text.contains("tax") || text.contains("invoice") {
            return .receipt
        }
        if text.contains("delivered") || text.contains("liked") || text.contains("typed") || text.contains("imessage") {
            return .chat
        }
        if text.contains("http") || text.contains("www") || text.contains(".com") || text.contains("search") {
            return .webpage
        }
        if text.contains("gate") || text.contains("boarding") || text.contains("seat") || text.contains("ticket") {
            return .ticket
        }
        return .unknown
    }

    nonisolated static func similarIdentifiers(for item: DeckItem, excluding: Set<String>) -> [String] {
        var ids: [String] = []
        if let burst = item.burstIdentifier {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "burstIdentifier == %@", burst)
            let result = PHAsset.fetchAssets(with: options)
            result.enumerateObjects { asset, _, _ in
                let id = asset.localIdentifier
                if id != item.localIdentifier, !excluding.contains(id) {
                    ids.append(id)
                }
            }
        }

        let window: TimeInterval = item.category == .screenshots ? 10 : 2.5
        let start = item.creationDate.addingTimeInterval(-window)
        let end = item.creationDate.addingTimeInterval(window)
        let nearby = PhotoLibraryService.fetchAssets(
            predicate: NSPredicate(
                format: "creationDate >= %@ AND creationDate <= %@",
                start as NSDate,
                end as NSDate
            )
        )
        for asset in nearby where asset.localIdentifier != item.localIdentifier && !excluding.contains(asset.localIdentifier) {
            if !ids.contains(asset.localIdentifier) {
                ids.append(asset.localIdentifier)
            }
        }
        return Array(ids.prefix(8))
    }

    private static func thumbnail(for asset: PHAsset, side: CGFloat) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let flag = ResumeFlag()
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: side, height: side),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if flag.done { return }
                if (info?[PHImageCancelledKey] as? Bool) == true || info?[PHImageErrorKey] != nil {
                    flag.done = true
                    continuation.resume(returning: nil)
                    return
                }
                if let image {
                    flag.done = true
                    continuation.resume(returning: image.cgImage)
                }
            }
        }
    }
}

private final class ResumeFlag: @unchecked Sendable {
    var done = false
}
