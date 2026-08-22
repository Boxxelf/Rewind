import SwiftData
import SwiftUI

struct ProfileTabView: View {
    @Environment(PhotoLibraryService.self) private var photos
    @Query private var appStates: [AppStateRecord]
    @Query(sort: \FavoriteRecord.favoritedAt, order: .reverse) private var favorites: [FavoriteRecord]
    @Query(sort: \ChapterRecord.completedAt, order: .reverse) private var chapters: [ChapterRecord]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        let state = appStates.first
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Profile")
                    .font(RewindFont.title)
                    .foregroundStyle(Color.rewindTextPrimary)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                HStack(spacing: 24) {
                    stat(ByteFormat.string(state?.lifetimeBytesFreed ?? 0), label: "freed")
                    stat("\(state?.lifetimeReviewed ?? 0)", label: "reviewed")
                    stat("\(favorites.count)", label: "kept")
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Chapters")
                        .font(RewindFont.heading)
                        .foregroundStyle(Color.rewindTextPrimary)
                    if chapters.isEmpty {
                        Text("Chapter cards appear as you finish a season of photos.")
                            .font(RewindFont.caption)
                            .foregroundStyle(Color.rewindTextSecondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(chapters) { chapter in
                                    ChapterCardView(chapter: chapter, photos: photos, allowsExport: true)
                                        .frame(width: 220)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    Task { await MemoryNotification.requestAndSchedule() }
                } label: {
                    Text("Weekly memory reminder")
                        .font(RewindFont.body)
                        .foregroundStyle(Color.rewindTextPrimary)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorites")
                        .font(RewindFont.heading)
                        .foregroundStyle(Color.rewindTextPrimary)
                        .padding(.horizontal, 24)

                    if favorites.isEmpty {
                        Text("Kept photos land here.")
                            .font(RewindFont.caption)
                            .foregroundStyle(Color.rewindTextSecondary)
                            .padding(.horizontal, 24)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(favorites.prefix(30), id: \.localIdentifier) { favorite in
                                if let asset = photos.asset(for: favorite.localIdentifier) {
                                    AssetImageView(asset: asset)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy")
                        .font(RewindFont.heading)
                        .foregroundStyle(Color.rewindTextPrimary)
                    Text("Photos never leave this device. Vision and hashing stay on-device.")
                        .font(RewindFont.body)
                        .foregroundStyle(Color.rewindTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.rewindBackground.ignoresSafeArea())
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(RewindFont.heading)
                .monospacedDigit()
                .foregroundStyle(Color.rewindTextPrimary)
            Text(label)
                .font(RewindFont.caption)
                .foregroundStyle(Color.rewindTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
