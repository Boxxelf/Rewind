import Foundation
import Photos

nonisolated struct ShuffleCandidate: Identifiable, Sendable {
    var id: String
    var creationDate: Date
    var burstIdentifier: String?
    var asset: PHAsset? = nil
}

extension ShuffleCandidate: Equatable {
    static func == (lhs: ShuffleCandidate, rhs: ShuffleCandidate) -> Bool {
        lhs.id == rhs.id
            && lhs.creationDate == rhs.creationDate
            && lhs.burstIdentifier == rhs.burstIdentifier
    }
}

nonisolated enum DeckRandomizer {
    static let deckSizeRange = 20...30
    static let momentWindow: TimeInterval = 3

    static func weight(for date: Date, now: Date) -> Double {
        let days = max(1, now.timeIntervalSince(date) / 86_400)
        return pow(days, 0.55)
    }

    static func sameMoment(_ a: ShuffleCandidate, _ b: ShuffleCandidate) -> Bool {
        if let burstA = a.burstIdentifier, let burstB = b.burstIdentifier, burstA == burstB {
            return true
        }
        return abs(a.creationDate.timeIntervalSince(b.creationDate)) < momentWindow
    }

    static func makeDeck(
        from candidates: [ShuffleCandidate],
        now: Date = .now,
        deckSize: Int? = nil,
        biasFirstCardToOld: Bool = false,
        rng: inout some RandomNumberGenerator
    ) -> [ShuffleCandidate] {
        guard !candidates.isEmpty else { return [] }

        let target = min(
            candidates.count,
            deckSize ?? Int.random(in: deckSizeRange, using: &rng)
        )
        guard target > 0 else { return [] }

        var remaining = candidates
        var picked: [ShuffleCandidate] = []
        picked.reserveCapacity(target)

        while picked.count < target, !remaining.isEmpty {
            let weights = remaining.map { weight(for: $0.creationDate, now: now) }
            let index = weightedIndex(weights: weights, rng: &rng)
            picked.append(remaining.remove(at: index))
        }

        separateConsecutiveMoments(&picked)

        if biasFirstCardToOld, picked.count > 1 {
            let sorted = picked.enumerated().sorted { $0.element.creationDate < $1.element.creationDate }
            let cutoff = max(1, sorted.count / 6)
            let choice = sorted[Int.random(in: 0..<cutoff, using: &rng)]
            picked.swapAt(0, choice.offset)
            separateConsecutiveMoments(&picked)
        }

        return picked
    }

    static func makeDeck(
        from candidates: [ShuffleCandidate],
        now: Date = .now,
        deckSize: Int? = nil,
        biasFirstCardToOld: Bool = false
    ) -> [ShuffleCandidate] {
        var rng = SystemRandomNumberGenerator()
        return makeDeck(
            from: candidates,
            now: now,
            deckSize: deckSize,
            biasFirstCardToOld: biasFirstCardToOld,
            rng: &rng
        )
    }

    private static func weightedIndex(weights: [Double], rng: inout some RandomNumberGenerator) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else { return 0 }
        var draw = Double.random(in: 0..<total, using: &rng)
        for (index, weight) in weights.enumerated() {
            draw -= weight
            if draw <= 0 { return index }
        }
        return weights.count - 1
    }

    static func separateConsecutiveMoments(_ deck: inout [ShuffleCandidate]) {
        guard deck.count > 2 else { return }
        for index in 1..<deck.count {
            guard sameMoment(deck[index], deck[index - 1]) else { continue }
            if let swapIndex = (index + 1..<deck.count).first(where: { candidateIndex in
                !sameMoment(deck[candidateIndex], deck[index - 1])
                    && (candidateIndex + 1 >= deck.count || !sameMoment(deck[candidateIndex], deck[index + 1]))
            }) {
                deck.swapAt(index, swapIndex)
            }
        }
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
