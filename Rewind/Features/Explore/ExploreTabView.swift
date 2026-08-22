import MapKit
import Photos
import SwiftUI

struct ExploreTabView: View {
    var isActive = false
    @Environment(DeckSessionController.self) private var session

    @State private var mode: Mode = .map
    @State private var trips: [TripCluster] = []
    @State private var month = Date.now
    @State private var selectedDay: Date?
    @State private var monthAssets: [Date: [PHAsset]] = [:]
    @State private var isLoadingMap = false

    private let calendar = Calendar.current

    private enum Mode: String, CaseIterable {
        case map = "Map"
        case calendar = "Calendar"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Explore")
                .font(RewindFont.title)
                .foregroundStyle(Color.rewindTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Picker("Explore mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            if mode == .map {
                mapContent
            } else {
                calendarContent
            }
        }
        .background(Color.rewindBackground.ignoresSafeArea())
        .task(id: isActive && mode == .map) {
            guard isActive, mode == .map else { return }
            await loadTrips()
        }
        .task(id: monthKey) {
            guard isActive, mode == .calendar else { return }
            await loadMonth()
        }
        .onChange(of: mode) { _, newMode in
            if newMode == .calendar {
                Task { await loadMonth() }
            }
        }
    }

    private var monthKey: String {
        let comps = calendar.dateComponents([.year, .month], from: month)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(mode.rawValue)-\(isActive)"
    }

    private var mapContent: some View {
        ZStack {
            TripMapView(trips: trips) { trip in
                Task { await session.startScopedDeck(assets: trip.assets) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            if isLoadingMap {
                ProgressView()
                    .tint(Color.rewindTextSecondary)
            } else if trips.isEmpty {
                Text("No trips found yet.")
                    .font(RewindFont.body)
                    .foregroundStyle(Color.rewindTextSecondary)
            }
        }
    }

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text(month, format: .dateTime.month(.wide).year())
                    .font(RewindFont.heading)
                    .foregroundStyle(Color.rewindTextPrimary)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
            }
            .foregroundStyle(Color.rewindTextPrimary)
            .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(RewindFont.caption)
                        .foregroundStyle(Color.rewindTextSecondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal, 16)

            Button {
                let assets = PhotoLibraryService.onThisDayAssets()
                Task { await session.startScopedDeck(assets: assets) }
            } label: {
                Text("On This Day")
                    .font(RewindFont.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rewindSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rewindTextPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            Button {
                let day = selectedDay ?? calendar.startOfDay(for: .now)
                let assets = monthAssets[day] ?? PhotoLibraryService.assetsCreated(on: day)
                Task { await session.startScopedDeck(assets: assets) }
            } label: {
                Text(selectedDay == nil ? "Clean this day" : "Clean this day · \(dayCount(selectedDay!)) photos")
                    .font(RewindFont.body)
                    .foregroundStyle(Color.rewindTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().stroke(Color.rewindBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .disabled(selectedDay != nil && dayCount(selectedDay!) == 0)

            Spacer()
        }
    }

    private var weekdayHeaders: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private var monthCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = calendar.range(of: .day, in: .month, for: month)?.count ?? 0
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in 0..<days {
            cells.append(calendar.date(byAdding: .day, value: day, to: interval.start))
        }
        return cells
    }

    private func dayCell(_ day: Date) -> some View {
        let start = calendar.startOfDay(for: day)
        let count = monthAssets[start]?.count ?? 0
        let selected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        return Button {
            selectedDay = start
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(RewindFont.caption)
                    .fontWeight(selected ? .semibold : .regular)
                Circle()
                    .fill(count > 0 ? Color.rewindTextPrimary : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(Color.rewindTextPrimary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? Color.rewindTextPrimary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day.formatted(.dateTime.month().day())), \(count) photos")
    }

    private func dayCount(_ day: Date) -> Int {
        monthAssets[calendar.startOfDay(for: day)]?.count ?? 0
    }

    private func loadTrips() async {
        isLoadingMap = true
        let assets = await Task.detached(priority: .userInitiated) {
            PhotoLibraryService.locatedAssets(limit: 400)
        }.value
        trips = await Task.detached(priority: .utility) {
            Array(TripClusterer.clusters(from: assets).prefix(40))
        }.value
        isLoadingMap = false
    }

    private func loadMonth() async {
        let target = month
        let assets = await Task.detached(priority: .userInitiated) {
            PhotoLibraryService.assets(inMonth: target)
        }.value
        var grouped: [Date: [PHAsset]] = [:]
        for asset in assets {
            guard let date = asset.creationDate else { continue }
            let key = calendar.startOfDay(for: date)
            grouped[key, default: []].append(asset)
        }
        monthAssets = grouped
        if selectedDay == nil {
            let today = calendar.startOfDay(for: .now)
            if calendar.isDate(today, equalTo: target, toGranularity: .month) {
                selectedDay = today
            }
        }
    }

    private func shiftMonth(_ value: Int) {
        month = calendar.date(byAdding: .month, value: value, to: month) ?? month
        selectedDay = nil
    }
}
