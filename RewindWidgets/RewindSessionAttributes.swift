import ActivityKit
import Foundation

struct RewindSessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var remaining: Int
        var pendingText: String
    }

    var title: String
}
