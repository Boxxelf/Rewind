import Foundation
import SwiftData

@Model
final class ProcessedRecord {
    @Attribute(.unique) var localIdentifier: String
    var decisionRaw: String
    var processedAt: Date
    var categoryRaw: String
    var byteSize: Int64
    var burstIdentifier: String?
    var creationDate: Date?

    var decision: CardDecision {
        get { CardDecision(rawValue: decisionRaw) ?? .skip }
        set { decisionRaw = newValue.rawValue }
    }

    var category: MediaCategory {
        get { MediaCategory(rawValue: categoryRaw) ?? .photos }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        localIdentifier: String,
        decision: CardDecision,
        processedAt: Date = .now,
        category: MediaCategory,
        byteSize: Int64,
        burstIdentifier: String? = nil,
        creationDate: Date? = nil
    ) {
        self.localIdentifier = localIdentifier
        self.decisionRaw = decision.rawValue
        self.processedAt = processedAt
        self.categoryRaw = category.rawValue
        self.byteSize = byteSize
        self.burstIdentifier = burstIdentifier
        self.creationDate = creationDate
    }
}

@Model
final class LaterRecord {
    @Attribute(.unique) var localIdentifier: String
    var deferredAt: Date
    var deferralCount: Int
    var cooldownUntil: Date
    var categoryRaw: String
    var byteSize: Int64
    var burstIdentifier: String?
    var creationDate: Date?

    var category: MediaCategory {
        get { MediaCategory(rawValue: categoryRaw) ?? .photos }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        localIdentifier: String,
        deferredAt: Date = .now,
        deferralCount: Int = 1,
        cooldownUntil: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
        category: MediaCategory,
        byteSize: Int64,
        burstIdentifier: String? = nil,
        creationDate: Date? = nil
    ) {
        self.localIdentifier = localIdentifier
        self.deferredAt = deferredAt
        self.deferralCount = deferralCount
        self.cooldownUntil = cooldownUntil
        self.categoryRaw = category.rawValue
        self.byteSize = byteSize
        self.burstIdentifier = burstIdentifier
        self.creationDate = creationDate
    }
}

@Model
final class FavoriteRecord {
    @Attribute(.unique) var localIdentifier: String
    var favoritedAt: Date
    var categoryRaw: String
    var byteSize: Int64

    init(
        localIdentifier: String,
        favoritedAt: Date = .now,
        category: MediaCategory,
        byteSize: Int64
    ) {
        self.localIdentifier = localIdentifier
        self.favoritedAt = favoritedAt
        self.categoryRaw = category.rawValue
        self.byteSize = byteSize
    }
}

@Model
final class StagedDeletionRecord {
    @Attribute(.unique) var localIdentifier: String
    var byteSize: Int64
    var stagedAt: Date
    var categoryRaw: String
    var burstIdentifier: String?
    var creationDate: Date?

    init(
        localIdentifier: String,
        byteSize: Int64,
        stagedAt: Date = .now,
        category: MediaCategory,
        burstIdentifier: String? = nil,
        creationDate: Date? = nil
    ) {
        self.localIdentifier = localIdentifier
        self.byteSize = byteSize
        self.stagedAt = stagedAt
        self.categoryRaw = category.rawValue
        self.burstIdentifier = burstIdentifier
        self.creationDate = creationDate
    }
}

@Model
final class AppStateRecord {
    var hasCompletedOnboarding: Bool
    var coachingCardsRemaining: Int
    var lifetimeBytesFreed: Int64
    var lifetimeReviewed: Int
    var firstDeckUsedOldestBias: Bool
    var isPremiumUnlocked: Bool
    var decksDayKey: String
    var decksStartedToday: Int
    var notificationsAllowed: Bool

    init(
        hasCompletedOnboarding: Bool = false,
        coachingCardsRemaining: Int = 4,
        lifetimeBytesFreed: Int64 = 0,
        lifetimeReviewed: Int = 0,
        firstDeckUsedOldestBias: Bool = false,
        isPremiumUnlocked: Bool = false,
        decksDayKey: String = "",
        decksStartedToday: Int = 0,
        notificationsAllowed: Bool = false
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.coachingCardsRemaining = coachingCardsRemaining
        self.lifetimeBytesFreed = lifetimeBytesFreed
        self.lifetimeReviewed = lifetimeReviewed
        self.firstDeckUsedOldestBias = firstDeckUsedOldestBias
        self.isPremiumUnlocked = isPremiumUnlocked
        self.decksDayKey = decksDayKey
        self.decksStartedToday = decksStartedToday
        self.notificationsAllowed = notificationsAllowed
    }

    static let freeDecksPerDay = 3

    var canStartFreeDeck: Bool { true }

    func registerDeckStart(now: Date = .now) {
        let key = Self.dayKey(now)
        if decksDayKey != key {
            decksDayKey = key
            decksStartedToday = 0
        }
        decksStartedToday += 1
    }

    static func dayKey(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    static func current(in context: ModelContext) -> AppStateRecord {
        var descriptor = FetchDescriptor<AppStateRecord>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = AppStateRecord()
        context.insert(created)
        return created
    }
}

@Model
final class ChapterRecord {
    var title: String
    var startDate: Date
    var endDate: Date
    var heroIdentifier: String?
    var reviewedCount: Int
    var bytesFreed: Int64
    var completedAt: Date

    init(
        title: String,
        startDate: Date,
        endDate: Date,
        heroIdentifier: String? = nil,
        reviewedCount: Int,
        bytesFreed: Int64,
        completedAt: Date = .now
    ) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.heroIdentifier = heroIdentifier
        self.reviewedCount = reviewedCount
        self.bytesFreed = bytesFreed
        self.completedAt = completedAt
    }
}

enum RewindSchema {
    static var models: Schema {
        Schema([
            ProcessedRecord.self,
            LaterRecord.self,
            FavoriteRecord.self,
            StagedDeletionRecord.self,
            AppStateRecord.self,
            ChapterRecord.self,
        ])
    }
}
