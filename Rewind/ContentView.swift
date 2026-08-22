import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PhotoLibraryService.self) private var photos
    @Query private var appStates: [AppStateRecord]

    @State private var session: DeckSessionController?

    var body: some View {
        Group {
            if !(appStates.first?.hasCompletedOnboarding ?? false) {
                OnboardingView(onFinished: finishOnboarding)
            } else if let session {
                RootView()
                    .environment(session)
            } else {
                Color.rewindBackground.ignoresSafeArea()
            }
        }
        .background(Color.rewindBackground.ignoresSafeArea())
        .fontDesign(.rounded)
        .tint(Color.rewindTextPrimary)
        .task {
            await prepareSession()
            if RewindLaunchAction.pendingStartDeck {
                RewindLaunchAction.pendingStartDeck = false
                await session?.startDeck(resetSessionCounts: true)
            }
        }
        .onOpenURL { url in
            guard url.scheme == "rewind" else { return }
            RewindLaunchAction.pendingStartDeck = true
            Task {
                await session?.startDeck(resetSessionCounts: true)
                RewindLaunchAction.pendingStartDeck = false
            }
        }
        .onChange(of: photos.authorizationStatus) { _, _ in
            Task { await session?.bootstrap() }
        }
    }

    private func prepareSession() async {
        _ = AppStateRecord.current(in: modelContext)
        try? modelContext.save()
        if session == nil {
            let controller = DeckSessionController(modelContext: modelContext, photos: photos)
            session = controller
            await controller.bootstrap()
        }
    }

    private func finishOnboarding() {
        let state = AppStateRecord.current(in: modelContext)
        state.hasCompletedOnboarding = true
        try? modelContext.save()
        Task { await session?.bootstrap() }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: RewindSchema.models,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    ContentView()
        .environment(PhotoLibraryService())
        .modelContainer(container)
}
