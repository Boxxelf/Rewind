import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var yearly = true

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Rewind Premium")
                .font(RewindFont.title)
                .foregroundStyle(Color.rewindTextPrimary)

            VStack(alignment: .leading, spacing: 10) {
                bullet("Unlimited decks")
                bullet("Map trips and On This Day")
                bullet("Screenshot smart-assist")
                bullet("Later Stack resurfacing")
                bullet("Chapter card export")
            }

            HStack(spacing: 8) {
                plan("Monthly", selected: !yearly) { yearly = false }
                plan("Annual", selected: yearly) { yearly = true }
            }

            if let message = store.errorMessage {
                Text(message)
                    .font(RewindFont.caption)
                    .foregroundStyle(Color.rewindTextSecondary)
            }

            Button(action: purchase) {
                Text(store.isPurchasing ? "Working…" : "Continue")
                    .font(RewindFont.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rewindSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.rewindTextPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing)

            Button("Restore purchases") {
                Task { await store.restore() }
            }
            .font(RewindFont.caption)
            .foregroundStyle(Color.rewindTextSecondary)
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(28)
        .background(Color.rewindBackground.ignoresSafeArea())
        .task { await store.refresh() }
        .onChange(of: store.isPremium) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    private func bullet(_ text: String) -> some View {
        Text(text)
            .font(RewindFont.body)
            .foregroundStyle(Color.rewindTextPrimary)
    }

    private func plan(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RewindFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(selected ? Color.rewindSurface : Color.rewindTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? Color.rewindTextPrimary : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(Color.rewindBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func purchase() {
        Task {
            if yearly, let product = store.yearly {
                await store.purchase(product)
            } else if let product = store.monthly {
                await store.purchase(product)
            } else {
                store.markUnavailable()
            }
        }
    }
}
