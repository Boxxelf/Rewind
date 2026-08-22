import ActivityKit
import Foundation

struct RewindSessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var remaining: Int
        var pendingText: String
    }

    var title: String
}

enum RewindLiveActivity {
    static func start(remaining: Int, pendingText: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = RewindSessionAttributes(title: "Rewind")
        let state = RewindSessionAttributes.ContentState(remaining: remaining, pendingText: pendingText)
        do {
            _ = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
        } catch {
            return
        }
    }

    static func update(remaining: Int, pendingText: String) {
        let state = RewindSessionAttributes.ContentState(remaining: remaining, pendingText: pendingText)
        Task {
            for activity in Activity<RewindSessionAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    static func end() {
        Task {
            for activity in Activity<RewindSessionAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
