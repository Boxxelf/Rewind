import UIKit

enum RewindHaptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        soft.prepare()
        rigid.prepare()
        notify.prepare()
    }

    static func keep() {
        light.impactOccurred()
    }

    static func later() {
        light.impactOccurred()
    }

    static func delete() {
        soft.impactOccurred()
    }

    static func undo() {
        rigid.impactOccurred()
    }

    static func deckComplete() {
        notify.notificationOccurred(.success)
    }
}
