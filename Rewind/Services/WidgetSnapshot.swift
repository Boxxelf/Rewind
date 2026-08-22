import Foundation
import Photos
import UIKit
import WidgetKit

enum WidgetSnapshot {
    static let suiteName = "group.com.tinajiang.Rewind"
    static let payloadKey = "widget.payload"
    static let imageName = "widget-hero.jpg"

    struct Payload: Codable {
        var caption: String
        var remaining: Int
        var pendingText: String
        var reviewed: Int
        var hasPhoto: Bool
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    static var imageURL: URL? {
        containerURL?.appendingPathComponent(imageName)
    }

    static func read() -> Payload {
        guard let data = defaults?.data(forKey: payloadKey),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return Payload(caption: "Remember this?", remaining: 0, pendingText: "Start a deck", reviewed: 0, hasPhoto: false)
        }
        return payload
    }

    static func heroImage() -> UIImage? {
        guard let url = imageURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func publish(remaining: Int, pendingBytes: Int64, reviewed: Int, asset: PHAsset?) {
        let caption: String
        if let date = asset?.creationDate {
            caption = date.formatted(.dateTime.month(.wide).year())
        } else {
            caption = "Remember this?"
        }
        let payload = Payload(
            caption: caption,
            remaining: remaining,
            pendingText: ByteFormat.string(pendingBytes) + " pending",
            reviewed: reviewed,
            hasPhoto: asset != nil
        )
        if let data = try? JSONEncoder().encode(payload) {
            defaults?.set(data, forKey: payloadKey)
        }
        if let asset {
            writeHero(from: asset)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func writeHero(from asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 800, height: 1000),
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            guard let image, !degraded, let url = imageURL, let data = image.jpegData(compressionQuality: 0.82) else { return }
            try? data.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
