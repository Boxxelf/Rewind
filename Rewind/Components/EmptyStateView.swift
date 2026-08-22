import SwiftUI

struct EmptyStateView: View {
    let title: String
    var suggestion: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.rewindTextSecondary)
                .accessibilityHidden(true)

            Text(title)
                .font(RewindFont.heading)
                .foregroundStyle(Color.rewindTextPrimary)

            if let suggestion {
                Button(action: { action?() }) {
                    Text(suggestion)
                        .font(RewindFont.caption)
                        .foregroundStyle(Color.rewindTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().stroke(Color.rewindBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            } else if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(RewindFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rewindSurface)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.rewindTextPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PermissionDeniedView: View {
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Photos access is off.")
                .font(RewindFont.heading)
                .foregroundStyle(Color.rewindTextPrimary)

            Text("Rewind needs access to the photos on this device. Nothing ever leaves the device.")
                .font(RewindFont.body)
                .foregroundStyle(Color.rewindTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(RewindFont.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rewindSurface)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.rewindTextPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
