import Foundation

enum CardDecision: String, Codable, Sendable {
    case delete
    case keep
    case skip
    case later

    var accessibilityName: String {
        switch self {
        case .delete: "Delete"
        case .keep: "Keep"
        case .skip: "Skip"
        case .later: "Later"
        }
    }
}

enum SwipeAxis: Sendable {
    case horizontal
    case vertical
}

enum SwipeDirection: Sendable {
    case up, down, left, right

    var decision: CardDecision {
        switch self {
        case .up: .delete
        case .right: .keep
        case .left: .skip
        case .down: .later
        }
    }
}
