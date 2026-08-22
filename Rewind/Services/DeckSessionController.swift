import Foundation
import Photos
import SwiftData
import UIKit

struct UndoPayload: Equatable {
    let item: DeckItem
    let decision: CardDecision
}

struct CategoryProgress: Equatable {
    var processed: Int
    var total: Int

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(processed) / Double(total))
    }
}

@Observable
final class DeckSessionController {
    private let modelContext: ModelContext
    private let photos: PhotoLibraryService

    private(set) var category: MediaCategory = .photos
    private(set) var deck: [DeckItem] = []
    private(set) var cursor: Int = 0
    private(set) var deletedCount = 0
    private(set) var keptCount = 0
    private(set) var skippedCount = 0
    private(set) var laterCount = 0
    private(set) var isComplete = false
    private(set) var isLoading = false
    private(set) var undo: UndoPayload?
    private(set) var progress: [MediaCategory: CategoryProgress] = [:]
    private(set) var favoriteCount = 0
    private(set) var laterInboxCount = 0
    private(set) var stagedItems: [StagedDeletionRecord] = []
    private(set) var coachingRemaining = 0
    private(set) var newlyCompletedChapter: ChapterRecord?

    private var undoHideTask: Task<Void, Never>?
    private var lastPrefetchIDs: [String] = []
    private var byteSizeTask: Task<Void, Never>?
    private var deckGeneration = 0

    init(modelContext: ModelContext, photos: PhotoLibraryService) {
        self.modelContext = modelContext
        self.photos = photos
    }

    var current: DeckItem? {
        guard cursor < deck.count else { return nil }
        return deck[cursor]
    }

    var peek: DeckItem? {
        guard cursor + 1 < deck.count else { return nil }
        return deck[cursor + 1]
    }

    var remainingCount: Int {
        max(0, deck.count - cursor)
    }

    var stagedBytes: Int64 {
        stagedItems.reduce(0) { $0 + $1.byteSize }
    }

    var hasAnythingInDeckPool: Bool {
        (progress[category]?.total ?? 0) > (progress[category]?.processed ?? 0)
    }

    func bootstrap() async {
        _ = AppStateRecord.current(in: modelContext)
        refreshLedgerCounts(includeLibraryTotals: true)
        coachingRemaining = AppStateRecord.current(in: modelContext).coachingCardsRemaining
        guard photos.isAuthorized else { return }
        await startDeck(resetSessionCounts: true)
    }

    func startDeck(resetSessionCounts: Bool) async {
        isLoading = true
        isComplete = false
        if resetSessionCounts {
            deletedCount = 0
            keptCount = 0
            skippedCount = 0
            laterCount = 0
        }
        undo = nil
        undoHideTask?.cancel()
        byteSizeTask?.cancel()
        deckGeneration += 1
        let generation = deckGeneration

        let appState = AppStateRecord.current(in: modelContext)
        let biasOld = !appState.firstDeckUsedOldestBias
        let excluding = excludedIdentifiers()
        let selectedCategory = category
        let now = Date.now
        let laterLookup: [String: (resurfaced: Bool, count: Int)] = Dictionary(
            uniqueKeysWithValues: laterItems().map { record in
                (record.localIdentifier, (resurfaced: record.cooldownUntil <= now, count: record.deferralCount))
            }
        )

        let items = await Task.detached(priority: .userInitiated) {
            let candidates = PhotoLibraryService.fetchCandidates(in: selectedCategory, excluding: excluding)
            let picked = DeckRandomizer.makeDeck(from: candidates, biasFirstCardToOld: biasOld)
            return picked.compactMap { candidate -> DeckItem? in
                guard let asset = candidate.asset else { return nil }
                let later = laterLookup[candidate.id]
                return DeckItem(
                    localIdentifier: candidate.id,
                    asset: asset,
                    category: selectedCategory,
                    byteSize: 0,
                    creationDate: candidate.creationDate,
                    burstIdentifier: candidate.burstIdentifier,
                    isResurfaced: later?.resurfaced ?? false,
                    deferralCount: later?.count ?? 0,
                    screenshotTag: nil,
                    similarIdentifiers: []
                )
            }
        }.value

        guard generation == deckGeneration else { return }

        deck = items
        cursor = 0
        if !items.isEmpty, !appState.firstDeckUsedOldestBias {
            appState.firstDeckUsedOldestBias = true
        }
        save()
        refreshLedgerCounts(includeLibraryTotals: true)
        isLoading = false
        isComplete = items.isEmpty
        prefetchAroundCursor()
        fillByteSizes(for: items, generation: generation)
        if !items.isEmpty {
            appState.registerDeckStart()
            save()
            RewindLiveActivity.start(
                remaining: remainingCount,
                pendingText: ByteFormat.string(stagedBytes) + " pending"
            )
            publishWidgetSnapshot()
        }
        await refreshAssistForCurrent()
        if items.isEmpty {
            RewindLiveActivity.end()
        }
    }

    func startScopedDeck(assets: [PHAsset], titleIgnored: String = "") async {
        isLoading = true
        isComplete = false
        deletedCount = 0
        keptCount = 0
        skippedCount = 0
        laterCount = 0
        undo = nil
        byteSizeTask?.cancel()
        deckGeneration += 1
        let generation = deckGeneration
        let selectedCategory = category
        let excluding = excludedIdentifiers()
        let items = assets.compactMap { asset -> DeckItem? in
            let id = asset.localIdentifier
            guard !excluding.contains(id) else { return nil }
            return DeckItem(
                localIdentifier: id,
                asset: asset,
                category: selectedCategory,
                byteSize: 0,
                creationDate: asset.creationDate ?? .now,
                burstIdentifier: asset.burstIdentifier,
                isResurfaced: false,
                deferralCount: 0,
                screenshotTag: nil,
                similarIdentifiers: []
            )
        }
        deck = items
        cursor = 0
        isLoading = false
        isComplete = items.isEmpty
        prefetchAroundCursor()
        fillByteSizes(for: items, generation: generation)
        AppStateRecord.current(in: modelContext).registerDeckStart()
        save()
        await refreshAssistForCurrent()
        publishWidgetSnapshot()
    }

    func switchCategory(_ newCategory: MediaCategory) async {
        guard newCategory != category else { return }
        category = newCategory
        await startDeck(resetSessionCounts: true)
    }

    func refreshAssistForCurrent() async {
        guard let item = current else { return }
        let identifier = item.localIdentifier
        try? await Task.sleep(for: .milliseconds(250))
        guard current?.localIdentifier == identifier else { return }
        let excluding = excludedIdentifiers()
        let similar = await Task.detached(priority: .utility) {
            MediaAssist.similarIdentifiers(for: item, excluding: excluding)
        }.value
        var tag: String?
        if item.category == .screenshots {
            let asset = item.asset
            tag = await Task.detached(priority: .utility) {
                await MediaAssist.classifyScreenshot(asset: asset)
            }.value.title
        }
        guard current?.localIdentifier == identifier else { return }
        if let index = deck.firstIndex(where: { $0.localIdentifier == identifier }) {
            deck[index] = item.withAssist(tag: tag, similar: similar)
        }
    }

    func resolveSimilar(keepID: String, deleteIDs: [String]) {
        for id in deleteIDs {
            guard let asset = photos.asset(for: id) else { continue }
            let item = DeckItem(
                localIdentifier: id,
                asset: asset,
                category: category,
                byteSize: 0,
                creationDate: asset.creationDate ?? .now,
                burstIdentifier: asset.burstIdentifier,
                isResurfaced: false,
                deferralCount: 0,
                screenshotTag: nil,
                similarIdentifiers: []
            )
            persist(.delete, for: item)
            deletedCount += 1
            deck.removeAll { $0.localIdentifier == id }
        }
        if current?.localIdentifier == keepID {
            apply(.keep)
        }
        save()
        refreshLedgerCounts()
    }

    func apply(_ decision: CardDecision) {
        guard let item = current else { return }
        persist(decision, for: item)
        bumpSessionCount(decision)
        AppStateRecord.current(in: modelContext).lifetimeReviewed += 1
        if coachingRemaining > 0 {
            coachingRemaining -= 1
            AppStateRecord.current(in: modelContext).coachingCardsRemaining = coachingRemaining
        }
        save()
        refreshLedgerCounts()

        undo = UndoPayload(item: item, decision: decision)
        scheduleUndoHide()

        cursor += 1
        if cursor >= deck.count {
            isComplete = true
            RewindHaptics.deckComplete()
        }
        prefetchAroundCursor()
        if isComplete {
            RewindLiveActivity.update(
                remaining: remainingCount,
                pendingText: ByteFormat.string(stagedBytes) + " pending"
            )
            publishWidgetSnapshot()
            newlyCompletedChapter = ChapterBuilder.harvestIfNeeded(in: modelContext)
            RewindLiveActivity.end()
        } else if remainingCount % 4 == 0 {
            RewindLiveActivity.update(
                remaining: remainingCount,
                pendingText: ByteFormat.string(stagedBytes) + " pending"
            )
            Task { await refreshAssistForCurrent() }
        } else {
            Task { await refreshAssistForCurrent() }
        }
    }

    func undoLast() {
        guard let payload = undo else { return }
        reverse(payload)
        cursor = max(0, cursor - 1)
        isComplete = false
        undo = nil
        undoHideTask?.cancel()
        rewindSessionCount(payload.decision)
        let appState = AppStateRecord.current(in: modelContext)
        appState.lifetimeReviewed = max(0, appState.lifetimeReviewed - 1)
        save()
        refreshLedgerCounts()
        publishWidgetSnapshot()
        RewindHaptics.undo()
    }

    func rescueFromStaging(identifier: String) {
        if let record = stagedItems.first(where: { $0.localIdentifier == identifier }) {
            modelContext.delete(record)
        }
        if let processed = processedRecord(for: identifier) {
            modelContext.delete(processed)
        }
        if undo?.item.localIdentifier == identifier {
            undo = nil
        }
        save()
        refreshLedgerCounts()
    }

    func commitDeletions() async throws {
        let identifiers = stagedItems.map(\.localIdentifier)
        let bytes = stagedBytes
        guard !identifiers.isEmpty else { return }
        try await photos.deleteAssets(identifiers: identifiers)
        let appState = AppStateRecord.current(in: modelContext)
        appState.lifetimeBytesFreed += bytes
        for record in stagedItems {
            modelContext.delete(record)
        }
        save()
        refreshLedgerCounts()
    }

    func laterItems() -> [LaterRecord] {
        let descriptor = FetchDescriptor<LaterRecord>(
            sortBy: [SortDescriptor(\.deferredAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func favoriteIdentifiers() -> [String] {
        let descriptor = FetchDescriptor<FavoriteRecord>(
            sortBy: [SortDescriptor(\.favoritedAt, order: .reverse)]
        )
        return ((try? modelContext.fetch(descriptor)) ?? []).map(\.localIdentifier)
    }

    func resolveLaterItem(_ record: LaterRecord, decision: CardDecision) {
        guard let asset = photos.asset(for: record.localIdentifier) else {
            modelContext.delete(record)
            save()
            refreshLedgerCounts()
            return
        }
        let item = DeckItem(
            localIdentifier: record.localIdentifier,
            asset: asset,
            category: record.category,
            byteSize: record.byteSize,
            creationDate: record.creationDate ?? .now,
            burstIdentifier: record.burstIdentifier,
            isResurfaced: true,
            deferralCount: record.deferralCount,
            screenshotTag: nil,
            similarIdentifiers: []
        )
        modelContext.delete(record)
        persist(decision, for: item)
        AppStateRecord.current(in: modelContext).lifetimeReviewed += 1
        save()
        refreshLedgerCounts()
    }

    private func publishWidgetSnapshot() {
        WidgetSnapshot.publish(
            remaining: remainingCount,
            pendingBytes: stagedBytes,
            reviewed: AppStateRecord.current(in: modelContext).lifetimeReviewed,
            asset: current?.asset ?? peek?.asset
        )
    }

    private func persist(_ decision: CardDecision, for item: DeckItem) {
        switch decision {
        case .delete:
            if stagedRecord(for: item.localIdentifier) == nil {
                modelContext.insert(
                    StagedDeletionRecord(
                        localIdentifier: item.localIdentifier,
                        byteSize: item.byteSize,
                        category: item.category,
                        burstIdentifier: item.burstIdentifier,
                        creationDate: item.creationDate
                    )
                )
            }
            upsertProcessed(item, decision: .delete)
        case .keep:
            if favoriteRecord(for: item.localIdentifier) == nil {
                modelContext.insert(
                    FavoriteRecord(
                        localIdentifier: item.localIdentifier,
                        category: item.category,
                        byteSize: item.byteSize
                    )
                )
            }
            upsertProcessed(item, decision: .keep)
            if let later = laterRecord(for: item.localIdentifier) {
                modelContext.delete(later)
            }
        case .skip:
            upsertProcessed(item, decision: .skip)
            if let later = laterRecord(for: item.localIdentifier) {
                modelContext.delete(later)
            }
        case .later:
            if let existing = laterRecord(for: item.localIdentifier) {
                existing.deferralCount += 1
                existing.deferredAt = .now
                existing.cooldownUntil = Date().addingTimeInterval(7 * 24 * 60 * 60)
            } else {
                modelContext.insert(
                    LaterRecord(
                        localIdentifier: item.localIdentifier,
                        category: item.category,
                        byteSize: item.byteSize,
                        burstIdentifier: item.burstIdentifier,
                        creationDate: item.creationDate
                    )
                )
            }
            if let processed = processedRecord(for: item.localIdentifier) {
                modelContext.delete(processed)
            }
        }
    }

    private func reverse(_ payload: UndoPayload) {
        let id = payload.item.localIdentifier
        switch payload.decision {
        case .delete:
            if let staged = stagedRecord(for: id) { modelContext.delete(staged) }
            if let processed = processedRecord(for: id) { modelContext.delete(processed) }
        case .keep:
            if let favorite = favoriteRecord(for: id) { modelContext.delete(favorite) }
            if let processed = processedRecord(for: id) { modelContext.delete(processed) }
        case .skip:
            if let processed = processedRecord(for: id) { modelContext.delete(processed) }
        case .later:
            if let later = laterRecord(for: id) {
                if later.deferralCount <= 1 {
                    modelContext.delete(later)
                } else {
                    later.deferralCount -= 1
                }
            }
        }
    }

    private func upsertProcessed(_ item: DeckItem, decision: CardDecision) {
        if let existing = processedRecord(for: item.localIdentifier) {
            existing.decision = decision
            existing.processedAt = .now
        } else {
            modelContext.insert(
                ProcessedRecord(
                    localIdentifier: item.localIdentifier,
                    decision: decision,
                    category: item.category,
                    byteSize: item.byteSize,
                    burstIdentifier: item.burstIdentifier,
                    creationDate: item.creationDate
                )
            )
        }
    }

    private func bumpSessionCount(_ decision: CardDecision) {
        switch decision {
        case .delete: deletedCount += 1
        case .keep: keptCount += 1
        case .skip: skippedCount += 1
        case .later: laterCount += 1
        }
    }

    private func rewindSessionCount(_ decision: CardDecision) {
        switch decision {
        case .delete: deletedCount = max(0, deletedCount - 1)
        case .keep: keptCount = max(0, keptCount - 1)
        case .skip: skippedCount = max(0, skippedCount - 1)
        case .later: laterCount = max(0, laterCount - 1)
        }
    }

    private func excludedIdentifiers() -> Set<String> {
        let processed = ((try? modelContext.fetch(FetchDescriptor<ProcessedRecord>())) ?? [])
            .map(\.localIdentifier)
        let later = (try? modelContext.fetch(FetchDescriptor<LaterRecord>())) ?? []
        let blockedLater = later
            .filter { $0.cooldownUntil > .now }
            .map(\.localIdentifier)
        return Set(processed + blockedLater)
    }

    private func processedRecord(for identifier: String) -> ProcessedRecord? {
        var descriptor = FetchDescriptor<ProcessedRecord>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func laterRecord(for identifier: String) -> LaterRecord? {
        var descriptor = FetchDescriptor<LaterRecord>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func favoriteRecord(for identifier: String) -> FavoriteRecord? {
        var descriptor = FetchDescriptor<FavoriteRecord>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func stagedRecord(for identifier: String) -> StagedDeletionRecord? {
        var descriptor = FetchDescriptor<StagedDeletionRecord>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func refreshLedgerCounts(includeLibraryTotals: Bool = false) {
        let processed = (try? modelContext.fetch(FetchDescriptor<ProcessedRecord>())) ?? []
        stagedItems = ((try? modelContext.fetch(
            FetchDescriptor<StagedDeletionRecord>(sortBy: [SortDescriptor(\.stagedAt, order: .reverse)])
        )) ?? [])
        favoriteCount = ((try? modelContext.fetch(FetchDescriptor<FavoriteRecord>())) ?? []).count
        laterInboxCount = ((try? modelContext.fetch(FetchDescriptor<LaterRecord>())) ?? []).count

        let processedByCategory = Dictionary(grouping: processed, by: \.category)
        let doneByCategory = Dictionary(
            uniqueKeysWithValues: MediaCategory.allCases.map { category in
                (category, processedByCategory[category]?.count ?? 0)
            }
        )
        for category in MediaCategory.allCases {
            let done = doneByCategory[category] ?? 0
            let existingTotal = progress[category]?.total ?? 0
            progress[category] = CategoryProgress(processed: min(done, max(existingTotal, done)), total: existingTotal)
        }

        guard includeLibraryTotals, photos.isAuthorized else {
            if !photos.isAuthorized {
                for category in MediaCategory.allCases {
                    let done = doneByCategory[category] ?? 0
                    progress[category] = CategoryProgress(processed: done, total: 0)
                }
            }
            return
        }

        Task.detached(priority: .utility) {
            let totals = Dictionary(
                uniqueKeysWithValues: MediaCategory.allCases.map { category in
                    (category, PhotoLibraryService.count(in: category))
                }
            )
            await MainActor.run {
                for category in MediaCategory.allCases {
                    let done = doneByCategory[category] ?? 0
                    let total = totals[category] ?? 0
                    self.progress[category] = CategoryProgress(processed: min(done, total), total: total)
                }
            }
        }
    }

    private func fillByteSizes(for items: [DeckItem], generation: Int) {
        let sized = items.map { (id: $0.localIdentifier, asset: $0.asset) }
        byteSizeTask = Task.detached(priority: .utility) { [weak self] in
            var sizes: [String: Int64] = [:]
            sizes.reserveCapacity(sized.count)
            for item in sized {
                if Task.isCancelled { return }
                let bytes = PhotoLibraryService.byteSize(of: item.asset)
                if bytes > 0 {
                    sizes[item.id] = bytes
                }
            }
            await self?.applyByteSizes(sizes, generation: generation)
        }
    }

    private func applyByteSizes(_ sizes: [String: Int64], generation: Int) {
        guard generation == deckGeneration, !sizes.isEmpty else { return }
        let limit = min(deck.count, cursor + 2)
        for index in cursor..<limit {
            if let size = sizes[deck[index].localIdentifier], size > 0 {
                deck[index] = deck[index].withByteSize(size)
            }
        }
        if let undo, let size = sizes[undo.item.localIdentifier], size > 0 {
            self.undo = UndoPayload(item: undo.item.withByteSize(size), decision: undo.decision)
        }
        for record in stagedItems where record.byteSize == 0 {
            if let size = sizes[record.localIdentifier] {
                record.byteSize = size
            }
        }
        save()
    }

    private func prefetchAroundCursor() {
        let slice = Array(deck.dropFirst(cursor).prefix(5))
        let ids = slice.map(\.localIdentifier)
        guard ids != lastPrefetchIDs else { return }
        lastPrefetchIDs = ids
        let screen = photosScreenSize()
        PhotoImageLoader.shared.prefetch(assets: slice.map(\.asset), size: screen)
    }

    private func photosScreenSize() -> CGSize {
        let bounds = UIKitScreenSize.current
        return CGSize(width: bounds.width - 40, height: bounds.height * 0.70)
    }

    private func scheduleUndoHide() {
        undoHideTask?.cancel()
        undoHideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.undo = nil
        }
    }

    private func save() {
        try? modelContext.save()
    }
}

private enum UIKitScreenSize {
    static var current: CGSize {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.screen.bounds.size ?? CGSize(width: 390, height: 844)
    }
}
