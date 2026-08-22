import SwiftUI

struct CardStackView: View {
    @Bindable var session: DeckSessionController
    var cardSize: CGSize
    var favoritesAnchor: CGPoint
    var islandAnchor: CGPoint
    var onPinchPreview: (DeckItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dragOffset: CGSize = .zero
    @State private var lockedAxis: SwipeAxis?
    @State private var grabY: CGFloat = 0
    @State private var departing: DepartingCard?
    @State private var stackFrame: CGRect = .zero
    @State private var absorbPulse = false

    private struct DepartingCard: Identifiable {
        let id: String
        let item: DeckItem
        let decision: CardDecision
        var offset: CGSize
        var rotation: Double
        var scale: CGFloat
        var stretch: CGSize
        var opacity: Double
    }

    var body: some View {
        ZStack {
            if let peek = session.peek {
                PhotoCardView(item: peek, cardSize: cardSize, isLifted: false)
                    .scaleEffect(peekScale)
                    .allowsHitTesting(false)
            }

            if let current = session.current {
                PhotoCardView(
                    item: current,
                    cardSize: cardSize,
                    isLifted: dragOffset != .zero
                )
                    .overlay {
                        DragDirectionOverlay(direction: activeDirection, progress: dragProgress)
                    }
                    .offset(dragOffset)
                    .rotationEffect(.degrees(rotation))
                    .highPriorityGesture(dragGesture(for: current))
                    .simultaneousGesture(previewGesture)
                    .opacity(departing == nil ? 1 : 0)
            }

            if let departing {
                PhotoCardView(item: departing.item, cardSize: cardSize, isLifted: true)
                    .overlay {
                        DragDirectionOverlay(
                            direction: swipeDirection(for: departing.decision),
                            progress: 1
                        )
                    }
                    .offset(departing.offset)
                    .rotationEffect(.degrees(departing.rotation))
                    .scaleEffect(x: departing.scale * departing.stretch.width, y: departing.scale * departing.stretch.height)
                    .opacity(departing.opacity)
                    .allowsHitTesting(false)
            }

            if absorbPulse {
                Circle()
                    .fill(Color.rewindDelete.opacity(0.55))
                    .frame(width: 22, height: 22)
                    .blur(radius: 8)
                    .position(x: islandAnchor.x - stackFrame.minX, y: islandAnchor.y - stackFrame.minY)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: StackFrameKey.self, value: geo.frame(in: .global))
            }
        )
        .onPreferenceChange(StackFrameKey.self) { stackFrame = $0 }
        .animation(nil, value: session.cursor)
    }

    private var peekScale: CGFloat {
        let lift = min(1, hypot(dragOffset.width, dragOffset.height) / 140)
        return 0.94 + (0.06 * lift)
    }

    private var rotation: Double {
        GestureMath.rotationDegrees(offset: dragOffset, cardSize: cardSize, grabY: grabY)
    }

    private var activeDirection: SwipeDirection? {
        GestureMath.direction(of: dragOffset, axis: lockedAxis)
    }

    private var dragProgress: CGFloat {
        GestureMath.progress(
            offset: dragOffset,
            cardSize: cardSize,
            axis: lockedAxis,
            threshold: session.category.commitThreshold
        )
    }

    private var previewGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                guard dragOffset == .zero, value.magnification > 1.12 else { return }
                if let current = session.current {
                    onPinchPreview(current)
                }
            }
    }

    private func dragGesture(for item: DeckItem) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                if grabY == 0 { grabY = value.startLocation.y }
                if lockedAxis == nil {
                    lockedAxis = GestureMath.lockAxis(translation: value.translation)
                }
                dragOffset = GestureMath.constrainedOffset(translation: value.translation, axis: lockedAxis)
            }
            .onEnded { value in
                let offset = GestureMath.constrainedOffset(translation: value.translation, axis: lockedAxis)
                let commit = GestureMath.shouldCommit(
                    offset: offset,
                    velocity: value.velocity,
                    cardSize: cardSize,
                    axis: lockedAxis,
                    threshold: session.category.commitThreshold
                )
                if commit, let direction = GestureMath.direction(of: offset, axis: lockedAxis) {
                    commitCard(item, decision: direction.decision, from: offset)
                } else {
                    withAnimation(RewindSpring.snappy) {
                        dragOffset = .zero
                        lockedAxis = nil
                        grabY = 0
                    }
                }
            }
    }

    private func commitCard(_ item: DeckItem, decision: CardDecision, from offset: CGSize) {
        playHaptic(decision)
        let startRotation = GestureMath.rotationDegrees(offset: offset, cardSize: cardSize, grabY: grabY)
        departing = DepartingCard(
            id: item.localIdentifier,
            item: item,
            decision: decision,
            offset: offset,
            rotation: startRotation,
            scale: 1,
            stretch: CGSize(width: 1, height: 1),
            opacity: 1
        )
        dragOffset = .zero
        lockedAxis = nil
        grabY = 0
        session.apply(decision)

        if reduceMotion {
            departing = nil
            return
        }

        withAnimation(decision == .delete ? RewindSpring.hero : RewindSpring.standard) {
            animateDeparture(decision)
        }

        let delay: Duration = decision == .delete ? .milliseconds(420) : .milliseconds(320)
        Task {
            try? await Task.sleep(for: delay)
            departing = nil
        }
    }

    private func animateDeparture(_ decision: CardDecision) {
        guard departing != nil else { return }
        switch decision {
        case .delete:
            departing?.offset = offsetTo(islandAnchor)
            departing?.scale = 0.06
            departing?.stretch = CGSize(width: 1.6, height: 0.42)
            departing?.rotation = 0
            departing?.opacity = 0.7
            absorbPulse = true
            Task {
                try? await Task.sleep(for: .milliseconds(420))
                absorbPulse = false
            }
        case .keep:
            departing?.offset = offsetTo(favoritesAnchor)
            departing?.scale = 0.12
            departing?.rotation = 8
            departing?.opacity = 0
        case .skip:
            departing?.offset = GestureMath.flyOffOffset(for: .left, in: cardSize)
            departing?.rotation = -10
            departing?.opacity = 0
        case .later:
            departing?.offset = GestureMath.flyOffOffset(for: .down, in: cardSize)
            departing?.rotation = 0
            departing?.opacity = 0
        }
    }

    private func offsetTo(_ globalPoint: CGPoint) -> CGSize {
        CGSize(
            width: globalPoint.x - stackFrame.midX,
            height: globalPoint.y - stackFrame.midY
        )
    }

    private func swipeDirection(for decision: CardDecision) -> SwipeDirection {
        switch decision {
        case .delete: .up
        case .keep: .right
        case .skip: .left
        case .later: .down
        }
    }

    private func playHaptic(_ decision: CardDecision) {
        switch decision {
        case .delete: RewindHaptics.delete()
        case .keep: RewindHaptics.keep()
        case .later: RewindHaptics.later()
        case .skip: break
        }
    }
}

private struct StackFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
