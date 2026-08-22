import AppIntents

struct StartRewindDeckIntent: AppIntent {
    static var title: LocalizedStringResource = "Start a Rewind deck"
    static var description = IntentDescription("Open Rewind and deal a new deck.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            RewindLaunchAction.pendingStartDeck = true
        }
        return .result()
    }
}

@MainActor
enum RewindLaunchAction {
    static var pendingStartDeck = false
}

struct RewindAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRewindDeckIntent(),
            phrases: [
                "Start a \(.applicationName) deck",
                "Rewind my photos with \(.applicationName)"
            ],
            shortTitle: "Start deck",
            systemImageName: "rectangle.stack"
        )
    }
}
