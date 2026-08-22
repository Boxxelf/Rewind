import CoreGraphics
import Foundation

enum GestureMath {
    static let lockDistance: CGFloat = 24
    static let axisBiasDegrees: CGFloat = 15
    static let flickVelocity: CGFloat = 900
    static let maxRotationDegrees: CGFloat = 12

    static func lockAxis(translation: CGSize, lockDistance: CGFloat = lockDistance) -> SwipeAxis? {
        let dx = translation.width
        let dy = translation.height
        let distance = hypot(dx, dy)
        guard distance >= lockDistance else { return nil }

        let angleFromHorizontal = abs(atan2(abs(dy), abs(dx))) * 180 / .pi
        let lower = 45 - axisBiasDegrees
        let upper = 45 + axisBiasDegrees
        if angleFromHorizontal < lower { return .horizontal }
        if angleFromHorizontal > upper { return .vertical }
        return nil
    }

    static func constrainedOffset(translation: CGSize, axis: SwipeAxis?) -> CGSize {
        switch axis {
        case .horizontal: CGSize(width: translation.width, height: 0)
        case .vertical: CGSize(width: 0, height: translation.height)
        case nil: translation
        }
    }

    static func direction(of offset: CGSize, axis: SwipeAxis?) -> SwipeDirection? {
        switch axis {
        case .horizontal:
            return offset.width >= 0 ? .right : .left
        case .vertical:
            return offset.height >= 0 ? .down : .up
        case nil:
            if offset == .zero { return nil }
            if abs(offset.width) > abs(offset.height) {
                return offset.width >= 0 ? .right : .left
            }
            return offset.height >= 0 ? .down : .up
        }
    }

    static func progress(
        offset: CGSize,
        cardSize: CGSize,
        axis: SwipeAxis?,
        threshold: CGFloat
    ) -> CGFloat {
        let travel: CGFloat
        let dimension: CGFloat
        switch axis ?? (abs(offset.width) > abs(offset.height) ? .horizontal : .vertical) {
        case .horizontal:
            travel = abs(offset.width)
            dimension = max(cardSize.width, 1)
        case .vertical:
            travel = abs(offset.height)
            dimension = max(cardSize.height, 1)
        }
        return min(1, travel / max(dimension * threshold, 1))
    }

    static func shouldCommit(
        offset: CGSize,
        velocity: CGSize,
        cardSize: CGSize,
        axis: SwipeAxis?,
        threshold: CGFloat
    ) -> Bool {
        let progressValue = progress(offset: offset, cardSize: cardSize, axis: axis, threshold: threshold)
        if progressValue >= 1 { return true }

        let locked = axis ?? (abs(offset.width) > abs(offset.height) ? .horizontal : .vertical)
        switch locked {
        case .horizontal:
            let sameDirection = (offset.width >= 0 && velocity.width > 0) || (offset.width < 0 && velocity.width < 0)
            return sameDirection && abs(velocity.width) >= flickVelocity
        case .vertical:
            let sameDirection = (offset.height >= 0 && velocity.height > 0) || (offset.height < 0 && velocity.height < 0)
            return sameDirection && abs(velocity.height) >= flickVelocity
        }
    }

    static func rotationDegrees(
        offset: CGSize,
        cardSize: CGSize,
        grabY: CGFloat
    ) -> Double {
        let width = max(cardSize.width, 1)
        let height = max(cardSize.height, 1)
        let fromCenter = (grabY - height / 2) / (height / 2)
        let sign: CGFloat = fromCenter < 0 ? 1 : -1
        let raw = (offset.width / width) * maxRotationDegrees * sign
        return Double(min(max(raw, -maxRotationDegrees), maxRotationDegrees))
    }

    static func flyOffOffset(for direction: SwipeDirection, in size: CGSize) -> CGSize {
        switch direction {
        case .left: CGSize(width: -size.width * 1.4, height: 0)
        case .right: CGSize(width: size.width * 1.4, height: -size.height * 0.55)
        case .up: CGSize(width: 0, height: -size.height * 1.2)
        case .down: CGSize(width: 0, height: size.height * 1.1)
        }
    }
}
