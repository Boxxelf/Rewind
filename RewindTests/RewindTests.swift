import CoreGraphics
import Foundation
import Testing
@testable import Rewind

@MainActor
struct DeckRandomizerTests {
    @Test func deckSizeStaysWithinRange() {
        let candidates = (0..<80).map { index in
            ShuffleCandidate(
                id: "\(index)",
                creationDate: Date(timeIntervalSince1970: Double(index) * 86_400),
                burstIdentifier: nil
            )
        }
        var rng = SeededGenerator(seed: 42)
        let deck = DeckRandomizer.makeDeck(from: candidates, now: Date(timeIntervalSince1970: 80 * 86_400), rng: &rng)
        #expect(DeckRandomizer.deckSizeRange.contains(deck.count))
        #expect(Set(deck.map(\.id)).count == deck.count)
    }

    @Test func consecutiveBurstPhotosAreSeparated() {
        let now = Date(timeIntervalSince1970: 10_000)
        var candidates: [ShuffleCandidate] = (0..<12).map { index in
            ShuffleCandidate(
                id: "burst-\(index)",
                creationDate: now,
                burstIdentifier: "burst-a"
            )
        }
        candidates.append(contentsOf: (0..<12).map { index in
            ShuffleCandidate(
                id: "other-\(index)",
                creationDate: now.addingTimeInterval(Double(index + 1) * 86_400),
                burstIdentifier: "other-\(index)"
            )
        })

        var deck = Array(candidates)
        DeckRandomizer.separateConsecutiveMoments(&deck)
        for index in 1..<deck.count {
            #expect(!DeckRandomizer.sameMoment(deck[index], deck[index - 1]) || index == deck.count - 1)
        }
    }

    @Test func olderPhotosReceiveHigherWeight() {
        let now = Date(timeIntervalSince1970: 100 * 86_400)
        let old = DeckRandomizer.weight(for: Date(timeIntervalSince1970: 0), now: now)
        let recent = DeckRandomizer.weight(for: Date(timeIntervalSince1970: 99 * 86_400), now: now)
        #expect(old > recent)
    }

    @Test func firstCardBiasPrefersOlderPhotos() {
        let candidates = (0..<30).map { index in
            ShuffleCandidate(
                id: "\(index)",
                creationDate: Date(timeIntervalSince1970: Double(index) * 86_400),
                burstIdentifier: nil
            )
        }
        var rng = SeededGenerator(seed: 7)
        let deck = DeckRandomizer.makeDeck(
            from: candidates,
            now: Date(timeIntervalSince1970: 30 * 86_400),
            deckSize: 20,
            biasFirstCardToOld: true,
            rng: &rng
        )
        let oldestIDs = Set(deck.sorted { $0.creationDate < $1.creationDate }.prefix(max(1, deck.count / 6)).map(\.id))
        #expect(oldestIDs.contains(deck[0].id))
    }
}

@MainActor
struct GestureMathTests {
    @Test func locksHorizontalWhenAngleIsShallow() {
        let axis = GestureMath.lockAxis(translation: CGSize(width: 80, height: 8))
        #expect(axis == .horizontal)
    }

    @Test func locksVerticalWhenAngleIsSteep() {
        let axis = GestureMath.lockAxis(translation: CGSize(width: 8, height: -80))
        #expect(axis == .vertical)
    }

    @Test func waitsInDiagonalZone() {
        let axis = GestureMath.lockAxis(translation: CGSize(width: 50, height: 50))
        #expect(axis == nil)
    }

    @Test func commitUsesTravelThreshold() {
        let should = GestureMath.shouldCommit(
            offset: CGSize(width: 0, height: -140),
            velocity: .zero,
            cardSize: CGSize(width: 320, height: 420),
            axis: .vertical,
            threshold: 0.3
        )
        #expect(should)
    }

    @Test func flickCommitsBeforeThreshold() {
        let should = GestureMath.shouldCommit(
            offset: CGSize(width: 40, height: 0),
            velocity: CGSize(width: 1_200, height: 0),
            cardSize: CGSize(width: 320, height: 420),
            axis: .horizontal,
            threshold: 0.3
        )
        #expect(should)
    }

    @Test func rotationIsCapped() {
        let degrees = GestureMath.rotationDegrees(
            offset: CGSize(width: 400, height: 0),
            cardSize: CGSize(width: 300, height: 400),
            grabY: 20
        )
        #expect(abs(degrees) <= 12)
    }
}

@MainActor
struct ByteFormatTests {
    @Test func freeUpTitleUsesExactActionCopy() {
        let title = ByteFormat.freeUpTitle(1_200_000_000)
        #expect(title.hasPrefix("Free up "))
        #expect(!title.isEmpty)
    }
}

@MainActor
struct ChapterBuilderTests {
    @Test func seasonTitleUsesEnglish() {
        var parts = DateComponents()
        parts.year = 2024
        parts.month = 7
        parts.day = 1
        let date = Calendar(identifier: .gregorian).date(from: parts)!
        #expect(ChapterBuilder.seasonTitle(for: date, calendar: Calendar(identifier: .gregorian)) == "Summer 2024")
    }
}
