import SwiftUI

struct PhotoCardView: View {
    let item: DeckItem
    var cardSize: CGSize
    var isLifted: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AssetImageView(asset: item.asset, targetSize: cardSize)
                .frame(width: cardSize.width, height: cardSize.height)

            if item.isVideo {
                Image(systemName: "play.circle")
                    .font(.system(size: 44, weight: .medium))
                    .symbolVariant(.none)
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.28)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 4) {
                if item.isResurfaced {
                    Text("Seen before")
                        .font(RewindFont.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                if item.offersKeep {
                    Text("Keep this one?")
                        .font(RewindFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                if let tag = item.screenshotTag {
                    Text(tag)
                        .font(RewindFont.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45), in: Capsule())
                        .foregroundStyle(.white)
                }
                HStack(spacing: 8) {
                    Text(item.creationDate, format: .dateTime.month(.wide).year())
                        .font(RewindFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.92))
                    if let duration = item.durationText {
                        Text(duration)
                            .font(RewindFont.caption)
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    if item.byteSize > 0 {
                        Text(ByteFormat.string(item.byteSize))
                            .font(RewindFont.caption)
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
            }
            .padding(16)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .clipShape(RoundedRectangle(cornerRadius: RewindShape.cardRadius, style: .continuous))
        .shadow(
            color: isLifted ? RewindShape.liftShadow.color : RewindShape.restShadow.color,
            radius: isLifted ? RewindShape.liftShadow.radius : RewindShape.restShadow.radius,
            y: isLifted ? RewindShape.liftShadow.y : RewindShape.restShadow.y
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardLabel)
        .accessibilityHint("Pinch out to preview")
    }

    private var cardLabel: String {
        var parts = [item.creationDate.formatted(.dateTime.month(.wide).year())]
        if item.isResurfaced { parts.insert("Seen before", at: 0) }
        if item.offersKeep { parts.insert("Keep this one?", at: 0) }
        if let tag = item.screenshotTag { parts.append(tag) }
        if let duration = item.durationText { parts.append("Video \(duration)") }
        return parts.joined(separator: ", ")
    }
}

struct DragDirectionOverlay: View {
    let direction: SwipeDirection?
    let progress: CGFloat

    var body: some View {
        ZStack {
            if let direction, progress > 0 {
                RoundedRectangle(cornerRadius: RewindShape.cardRadius, style: .continuous)
                    .fill(tint(for: direction).opacity(Double(progress) * 0.42))

                VStack(spacing: 8) {
                    Image(systemName: icon(for: direction))
                        .font(.system(size: 28, weight: .medium))
                        .symbolVariant(.none)
                    Text(direction.decision.accessibilityName)
                        .font(RewindFont.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .opacity(Double(min(1, progress * 1.4)))
                .offset(badgeOffset(for: direction))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func tint(for direction: SwipeDirection) -> Color {
        switch direction {
        case .up: .rewindDelete
        case .right: .rewindKeep
        case .left, .down: Color.black.opacity(0.55)
        }
    }

    private func icon(for direction: SwipeDirection) -> String {
        switch direction {
        case .up: "trash"
        case .right: "star"
        case .left: "arrow.left"
        case .down: "clock"
        }
    }

    private func badgeOffset(for direction: SwipeDirection) -> CGSize {
        switch direction {
        case .up: CGSize(width: 0, height: -80)
        case .down: CGSize(width: 0, height: 80)
        case .left: CGSize(width: -70, height: 0)
        case .right: CGSize(width: 70, height: 0)
        }
    }
}
