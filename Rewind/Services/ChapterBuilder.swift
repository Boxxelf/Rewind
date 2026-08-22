import Foundation
import SwiftData

enum ChapterBuilder {
    static func seasonTitle(for date: Date, calendar: Calendar = .current) -> String {
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let season: String
        switch month {
        case 3, 4, 5: season = "Spring"
        case 6, 7, 8: season = "Summer"
        case 9, 10, 11: season = "Fall"
        default: season = "Winter"
        }
        return "\(season) \(year)"
    }

    static func range(for date: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let startMonth: Int
        let startYear: Int
        switch month {
        case 3, 4, 5: startMonth = 3; startYear = year
        case 6, 7, 8: startMonth = 6; startYear = year
        case 9, 10, 11: startMonth = 9; startYear = year
        case 12: startMonth = 12; startYear = year
        default: startMonth = 12; startYear = year - 1
        }
        var startParts = DateComponents()
        startParts.year = startYear
        startParts.month = startMonth
        startParts.day = 1
        let start = calendar.date(from: startParts) ?? date
        let end = calendar.date(byAdding: .month, value: 3, to: start) ?? date
        return (start, end)
    }

    static func harvestIfNeeded(in context: ModelContext) -> ChapterRecord? {
        let processed = (try? context.fetch(FetchDescriptor<ProcessedRecord>())) ?? []
        let existing = (try? context.fetch(FetchDescriptor<ChapterRecord>())) ?? []
        let existingTitles = Set(existing.map(\.title))
        let grouped = Dictionary(grouping: processed) { record -> String in
            seasonTitle(for: record.creationDate ?? record.processedAt)
        }

        for (title, records) in grouped where records.count >= 12 && !existingTitles.contains(title) {
            guard let sample = records.first, let date = sample.creationDate ?? Optional(sample.processedAt) else { continue }
            let span = range(for: date)
            let hero = records.first(where: { $0.decision == .keep }) ?? records[0]
            let bytes = records.filter { $0.decision == .delete }.reduce(Int64(0)) { $0 + $1.byteSize }
            let chapter = ChapterRecord(
                title: title,
                startDate: span.start,
                endDate: span.end,
                heroIdentifier: hero.localIdentifier,
                reviewedCount: records.count,
                bytesFreed: bytes
            )
            context.insert(chapter)
            try? context.save()
            return chapter
        }
        return nil
    }
}
