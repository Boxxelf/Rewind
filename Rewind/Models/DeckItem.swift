import Foundation
import Photos

nonisolated struct DeckItem: Identifiable, Equatable {
    var id: String { localIdentifier }

    let localIdentifier: String
    let asset: PHAsset
    let category: MediaCategory
    let byteSize: Int64
    let creationDate: Date
    let burstIdentifier: String?
    let isResurfaced: Bool
    let deferralCount: Int
    let screenshotTag: String?
    let similarIdentifiers: [String]

    var offersKeep: Bool { deferralCount >= 3 }

    func withByteSize(_ size: Int64) -> DeckItem {
        DeckItem(
            localIdentifier: localIdentifier,
            asset: asset,
            category: category,
            byteSize: size,
            creationDate: creationDate,
            burstIdentifier: burstIdentifier,
            isResurfaced: isResurfaced,
            deferralCount: deferralCount,
            screenshotTag: screenshotTag,
            similarIdentifiers: similarIdentifiers
        )
    }

    func withAssist(tag: String?, similar: [String]) -> DeckItem {
        DeckItem(
            localIdentifier: localIdentifier,
            asset: asset,
            category: category,
            byteSize: byteSize,
            creationDate: creationDate,
            burstIdentifier: burstIdentifier,
            isResurfaced: isResurfaced,
            deferralCount: deferralCount,
            screenshotTag: tag ?? screenshotTag,
            similarIdentifiers: similar
        )
    }

    var isVideo: Bool { asset.mediaType == .video }

    var durationText: String? {
        guard isVideo else { return nil }
        let seconds = Int(asset.duration.rounded())
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    static func == (lhs: DeckItem, rhs: DeckItem) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
}
