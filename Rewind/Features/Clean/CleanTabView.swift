import SwiftUI

struct CleanTabView: View {
    @Environment(DeckSessionController.self) private var session
    @Environment(PhotoLibraryService.self) private var photos
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showStaging = false
    @State private var showLater = false
    @State private var hideSimilar = false
    @State private var previewItem: DeckItem?
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        @Bindable var session = session
        GeometryReader { geo in
            let cardWidth = geo.size.width - 40
            let cardHeight = min(geo.size.height * 0.62, cardWidth * 1.28)
            let global = geo.frame(in: .global)
            let island = CGPoint(x: global.midX, y: global.minY + 16)
            let favorites = CGPoint(x: global.maxX - 36, y: global.minY + 36)

            ZStack(alignment: .top) {
                Color.rewindBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    header
                    CategorySelector(session: session)

                    Spacer(minLength: 8)

                    mainStage(cardWidth: cardWidth, cardHeight: cardHeight, island: island, favorites: favorites)

                    Spacer(minLength: 8)

                    if session.current != nil, !session.isComplete {
                        FallbackActionBar(
                            onSkip: { commit(.skip) },
                            onDelete: { commit(.delete) },
                            onLater: { commit(.later) },
                            onKeep: { commit(.keep) }
                        )
                    }

                    BottomInfoStrip(
                        remaining: session.remainingCount,
                        stagedBytes: session.stagedBytes,
                        onTap: { showStaging = true }
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.top, 8)

                if session.undo != nil, session.undo?.decision == .delete {
                    UndoPill(onUndo: { session.undoLast() })
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
            .overlay {
                TwoFingerSwipeLeftOverlay {
                    session.undoLast()
                }
            }
            .overlay {
                if let previewItem {
                    MediaPreviewView(item: previewItem) {
                        self.previewItem = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showStaging) {
            StagingBinView(session: session)
        }
        .sheet(isPresented: $showLater) {
            LaterStackView(session: session)
        }
        .fullScreenCover(isPresented: Binding(
            get: { session.isComplete && !session.deck.isEmpty },
            set: { _ in }
        )) {
            SessionSummaryView(
                session: session,
                onFreeUp: { Task { await freeUp() } },
                onAnotherDeck: { dealAnotherDeck() }
            )
        }
        .alert("Couldn't delete", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
        .onChange(of: photos.libraryEpoch) { _, _ in
            session.refreshLedgerCounts(includeLibraryTotals: true)
        }
        .onChange(of: session.current?.localIdentifier) { _, _ in
            hideSimilar = false
        }
    }

    private var header: some View {
        HStack {
            Button { showLater = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "clock")
                        .font(.system(size: 18, weight: .medium))
                        .symbolVariant(.none)
                        .frame(width: 44, height: 44)
                    if session.laterInboxCount > 0 {
                        Text("\(session.laterInboxCount)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.rewindSurface)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.rewindTextPrimary, in: Capsule())
                            .offset(x: 6, y: 4)
                    }
                }
                .foregroundStyle(Color.rewindTextPrimary)
            }
            .accessibilityLabel("Later stack, \(session.laterInboxCount) items")

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star")
                    .font(.system(size: 16, weight: .medium))
                    .symbolVariant(.none)
                Text("\(session.favoriteCount)")
                    .font(RewindFont.caption)
                    .monospacedDigit()
            }
            .foregroundStyle(Color.rewindTextPrimary)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("\(session.favoriteCount) kept")
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func mainStage(
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        island: CGPoint,
        favorites: CGPoint
    ) -> some View {
        if photos.isDenied {
            PermissionDeniedView(onOpenSettings: photos.openSettings)
        } else if !photos.isAuthorized {
            PermissionDeniedView(onOpenSettings: photos.openSettings)
        } else if session.isLoading {
            ProgressView()
                .tint(Color.rewindTextSecondary)
                .frame(width: cardWidth, height: cardHeight)
        } else if (session.progress[session.category]?.total ?? 0) == 0 {
            EmptyStateView(
                title: session.category.emptyCopy,
                suggestion: suggestedOtherCategory.map { "Try \($0.title)" },
                action: suggestedOtherCategory.map { category in
                    { Task { await session.switchCategory(category) } }
                }
            )
            .frame(width: cardWidth, height: cardHeight)
        } else if session.isComplete, session.deck.isEmpty {
            emptyState
                .frame(width: cardWidth, height: cardHeight)
        } else {
            ZStack {
                CardStackView(
                    session: session,
                    cardSize: CGSize(width: cardWidth, height: cardHeight),
                    favoritesAnchor: favorites,
                    islandAnchor: island,
                    onPinchPreview: { item in
                        if previewItem == nil {
                            previewItem = item
                            RewindHaptics.keep()
                        }
                    }
                )

                if session.coachingRemaining > 0, session.current != nil, !session.isComplete {
                    GhostHandCoach(remaining: session.coachingRemaining)
                        .offset(y: cardHeight * 0.18)
                }

                if let current = session.current,
                   !hideSimilar,
                   current.similarIdentifiers.count >= 1,
                   !session.isComplete {
                    VStack {
                        Spacer()
                        SimilarPhotosTray(
                            current: current,
                            onKeepThisDeleteRest: {
                                session.resolveSimilar(keepID: current.localIdentifier, deleteIDs: current.similarIdentifiers)
                            },
                            onDismiss: { hideSimilar = true }
                        )
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
            .frame(width: cardWidth, height: cardHeight)
        }
    }

    private var suggestedOtherCategory: MediaCategory? {
        MediaCategory.allCases.first { category in
            category != session.category && (session.progress[category]?.total ?? 0) > (session.progress[category]?.processed ?? 0)
        }
    }

    private var emptyState: some View {
        if session.hasAnythingInDeckPool {
            EmptyStateView(
                title: "All caught up.",
                suggestion: "Deal another deck",
                action: { dealAnotherDeck() }
            )
        } else {
            EmptyStateView(
                title: "All caught up.",
                suggestion: suggestedOtherCategory.map { "Try \($0.title)" },
                action: suggestedOtherCategory.map { category in
                    { Task { await session.switchCategory(category) } }
                }
            )
        }
    }

    private func dealAnotherDeck() {
        Task { await session.startDeck(resetSessionCounts: true) }
    }

    private func commit(_ decision: CardDecision) {
        guard let current = session.current else { return }
        playHaptic(decision)
        if reduceMotion {
            session.apply(decision)
            return
        }
        session.apply(decision)
        _ = current
    }

    private func playHaptic(_ decision: CardDecision) {
        switch decision {
        case .delete: RewindHaptics.delete()
        case .keep: RewindHaptics.keep()
        case .later: RewindHaptics.later()
        case .skip: break
        }
    }

    private func freeUp() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await session.commitDeletions()
        } catch {
            deleteError = "The system dialog was cancelled or the photos could not be removed. They're still in the staging bin."
        }
    }
}
