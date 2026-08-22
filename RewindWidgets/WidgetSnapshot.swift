import Foundation
import UIKit

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

    static func read() -> Payload {
        let defaults = UserDefaults(suiteName: suiteName)
        guard let data = defaults?.data(forKey: payloadKey),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return Payload(
                caption: "Remember this?",
                remaining: 0,
                pendingText: "Start a deck",
                reviewed: 0,
                hasPhoto: false
            )
        }
        return payload
    }

    static func heroImage() -> UIImage? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) else {
            return nil
        }
        let url = container.appendingPathComponent(imageName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
