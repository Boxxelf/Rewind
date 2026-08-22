import SwiftUI

struct FallbackActionBar: View {
    var onSkip: () -> Void
    var onDelete: () -> Void
    var onLater: () -> Void
    var onKeep: () -> Void

    var body: some View {
        HStack(spacing: 22) {
            actionButton("arrow.left", name: "Skip", action: onSkip)
            actionButton("trash", name: "Delete", action: onDelete)
            actionButton("clock", name: "Later", action: onLater)
            actionButton("star", name: "Keep", action: onKeep)
        }
        .padding(.top, 8)
    }

    private func actionButton(_ systemName: String, name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .symbolVariant(.none)
                .foregroundStyle(Color.rewindTextPrimary)
                .frame(width: 48, height: 48)
                .background(
                    Circle().stroke(Color.rewindBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
    }
}

struct BottomInfoStrip: View {
    let remaining: Int
    let stagedBytes: Int64
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("\(remaining) left")
                    .monospacedDigit()
                Spacer()
                Text(ByteFormat.string(stagedBytes) + " pending")
                    .monospacedDigit()
            }
            .font(RewindFont.caption)
            .foregroundStyle(Color.rewindTextSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(remaining) left, \(ByteFormat.string(stagedBytes)) pending. Open staging bin.")
    }
}

struct UndoPill: View {
    var onUndo: () -> Void

    var body: some View {
        Button(action: onUndo) {
            Text("Undo")
                .font(RewindFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rewindTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.rewindBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Reverses the last card")
    }
}

struct GhostHandCoach: View {
    let remaining: Int
    @State private var bounce = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: remaining == 4 ? "arrow.up.left.and.arrow.down.right" : "hand.draw")
                .font(.system(size: 22, weight: .medium))
                .symbolVariant(.none)
            Text(hint)
                .font(RewindFont.caption)
        }
        .foregroundStyle(Color.rewindTextSecondary)
		.offset(hintOffset(phase: bounce ? 1.0 : 0.0))
        .opacity(bounce ? 1 : 0.65)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bounce)
        .onAppear { bounce = true }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var hint: String {
        switch remaining {
        case 4: "Pinch out to preview"
        case 3: "Swipe up to delete"
        case 2: "Swipe right to keep"
        default: "Swipe down for later"
        }
    }

    private func hintOffset(phase: Double) -> CGSize {
        let travel = 18 * phase
        switch remaining {
        case 4: return .zero
        case 3: return CGSize(width: 0, height: -travel)
        case 2: return CGSize(width: travel, height: 0)
        default: return CGSize(width: 0, height: travel)
        }
    }
}
