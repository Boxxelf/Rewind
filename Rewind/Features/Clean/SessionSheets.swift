import Photos
import SwiftUI

struct SessionSummaryView: View {
    @Bindable var session: DeckSessionController
    var onFreeUp: () -> Void
    var onAnotherDeck: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(ByteFormat.string(session.stagedBytes))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.rewindTextPrimary)

            Text("ready to free")
                .font(RewindFont.body)
                .foregroundStyle(Color.rewindTextSecondary)

            HStack(spacing: 18) {
                summaryStat("\(session.deletedCount)", label: "deleted")
                summaryStat("\(session.keptCount)", label: "kept")
                summaryStat("\(session.skippedCount)", label: "skipped")
                summaryStat("\(session.laterCount)", label: "later")
            }
            .padding(.top, 8)

            if let chapter = session.newlyCompletedChapter {
                Text(chapter.title)
                    .font(RewindFont.heading)
                    .foregroundStyle(Color.rewindTextPrimary)
                Text("A new chapter card is waiting in Profile.")
                    .font(RewindFont.caption)
                    .foregroundStyle(Color.rewindTextSecondary)
            }

            Spacer()

            VStack(spacing: 12) {
                if session.stagedBytes > 0 {
                    Button(action: onFreeUp) {
                        Text(ByteFormat.freeUpTitle(session.stagedBytes))
                            .font(RewindFont.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rewindSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.rewindTextPrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onAnotherDeck) {
                    Text("One more deck")
                        .font(RewindFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rewindTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().stroke(Color.rewindBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rewindBackground.ignoresSafeArea())
    }

    private func summaryStat(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(RewindFont.heading)
                .monospacedDigit()
                .foregroundStyle(Color.rewindTextPrimary)
            Text(label)
                .font(RewindFont.caption)
                .foregroundStyle(Color.rewindTextSecondary)
        }
        .frame(minWidth: 64)
    }
}

struct StagingBinView: View {
    @Bindable var session: DeckSessionController
    @Environment(PhotoLibraryService.self) private var photos
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if session.stagedItems.isEmpty {
                    Text("Nothing staged.")
                        .font(RewindFont.body)
                        .foregroundStyle(Color.rewindTextSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(session.stagedItems, id: \.localIdentifier) { record in
                                if let asset = photos.asset(for: record.localIdentifier) {
                                    Button {
                                        session.rescueFromStaging(identifier: record.localIdentifier)
                                    } label: {
                                        AssetImageView(asset: asset)
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                            .overlay(alignment: .bottomTrailing) {
                                                Image(systemName: "arrow.uturn.backward")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .padding(6)
                                                    .foregroundStyle(Color.rewindTextPrimary)
                                                    .background(.ultraThinMaterial, in: Circle())
                                                    .padding(6)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Rescue photo")
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.rewindBackground.ignoresSafeArea())
            .navigationTitle("Staging bin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.rewindTextPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(RewindShape.sheetRadius)
        .presentationBackground(.ultraThinMaterial)
    }
}

struct LaterStackView: View {
    @Bindable var session: DeckSessionController
    @Environment(PhotoLibraryService.self) private var photos
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        NavigationStack {
            let items = session.laterItems()
            Group {
                if items.isEmpty {
                    Text("Nothing saved for later.")
                        .font(RewindFont.body)
                        .foregroundStyle(Color.rewindTextSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(items, id: \.localIdentifier) { record in
                                if let asset = photos.asset(for: record.localIdentifier) {
                                    LaterMiniCard(record: record, asset: asset, session: session)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.rewindBackground.ignoresSafeArea())
            .navigationTitle("Later")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.rewindTextPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(RewindShape.sheetRadius)
        .presentationBackground(.ultraThinMaterial)
    }
}

private struct LaterMiniCard: View {
    let record: LaterRecord
    let asset: PHAsset
    @Bindable var session: DeckSessionController

    var body: some View {
        AssetImageView(asset: asset)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contextMenu {
                Button("Keep") { session.resolveLaterItem(record, decision: .keep) }
                Button("Skip") { session.resolveLaterItem(record, decision: .skip) }
                Button("Delete", role: .destructive) { session.resolveLaterItem(record, decision: .delete) }
            }
            .accessibilityLabel("Later photo. Long press to Keep, Skip, or Delete.")
    }
}
