import SwiftUI

struct CategorySelector: View {
    var session: DeckSessionController

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MediaCategory.allCases) { category in
                let selected = session.category == category
                let progress = session.progress[category] ?? CategoryProgress(processed: 0, total: 0)

                Button {
                    Task { await session.switchCategory(category) }
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Color.rewindBorder, lineWidth: 2)
                            Circle()
                                .trim(from: 0, to: progress.fraction)
                                .stroke(Color.rewindTextPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)

                        Text(category.title)
                            .font(RewindFont.caption)
                            .fontWeight(selected ? .semibold : .regular)
                    }
                    .foregroundStyle(selected ? Color.rewindSurface : Color.rewindTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(selected ? Color.rewindTextPrimary : Color.clear)
                    )
                    .overlay(
                        Capsule().stroke(selected ? Color.clear : Color.rewindBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(category.title), \(progress.processed) of \(progress.total) reviewed")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
