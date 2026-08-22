import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RewindWidgets: WidgetBundle {
    var body: some Widget {
        RememberWidget()
        RewindLiveActivityWidget()
    }
}

struct RememberEntry: TimelineEntry {
    let date: Date
    let payload: WidgetSnapshot.Payload
    let image: UIImage?
}

struct RememberProvider: TimelineProvider {
    func placeholder(in context: Context) -> RememberEntry {
        RememberEntry(
            date: .now,
            payload: WidgetSnapshot.Payload(
                caption: "March 2019",
                remaining: 24,
                pendingText: "1.2 GB pending",
                reviewed: 128,
                hasPhoto: false
            ),
            image: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RememberEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RememberEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .after(.now.addingTimeInterval(30 * 60))))
    }

    private func makeEntry() -> RememberEntry {
        RememberEntry(date: .now, payload: WidgetSnapshot.read(), image: WidgetSnapshot.heroImage())
    }
}

struct RememberWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RememberWidget", provider: RememberProvider()) { entry in
            RememberWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    if let image = entry.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.black
                    }
                }
        }
        .configurationDisplayName("Rewind")
        .description("A photo from your library, plus a shortcut to start a deck.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

struct RememberWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RememberEntry

    var body: some View {
        switch family {
        case .systemMedium:
            medium
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Rewind")
                    .font(.headline)
                Text(entry.payload.caption)
                    .font(.caption)
                Text(entry.payload.pendingText)
                    .font(.caption2)
            }
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text("\(entry.payload.remaining)")
                    .font(.headline.monospacedDigit())
                Text("left")
                    .font(.caption2)
            }
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rewind")
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
            Text(entry.payload.caption)
                .font(.headline)
            Text("Start a deck")
                .font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .shadow(radius: 4)
        .widgetURL(URL(string: "rewind://start-deck"))
    }

    private var medium: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Rewind")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text(entry.payload.caption)
                    .font(.title2.weight(.semibold))
                Text(entry.payload.pendingText)
                    .font(.caption.monospacedDigit())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.payload.remaining)")
                    .font(.title.monospacedDigit().weight(.semibold))
                Text("left in deck")
                    .font(.caption2)
                Text("\(entry.payload.reviewed) reviewed")
                    .font(.caption2)
            }
        }
        .foregroundStyle(.white)
        .shadow(radius: 6)
        .widgetURL(URL(string: "rewind://start-deck"))
    }
}

struct RewindLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RewindSessionAttributes.self) { context in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rewind")
                        .font(.headline)
                    Text(context.state.pendingText)
                        .font(.caption)
                }
                Spacer()
                Text("\(context.state.remaining) left")
                    .font(.title3.monospacedDigit())
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.25))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Rewind")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.remaining) left")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.pendingText)
                }
            } compactLeading: {
                Text("R")
            } compactTrailing: {
                Text("\(context.state.remaining)")
            } minimal: {
                Text("R")
            }
        }
    }
}
