import SwiftUI

struct OnboardingView: View {
    @Environment(PhotoLibraryService.self) private var photos
    var onFinished: () -> Void

    @State private var page = 0
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcome.tag(0)
                gestures.tag(1)
                previewHint.tag(2)
                permission.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(RewindSpring.standard, value: page)

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.rewindTextPrimary : Color.rewindBorder)
                        .frame(width: index == page ? 18 : 6, height: 6)
                }
            }
            .padding(.bottom, 16)

            Button(action: advance) {
                Text(primaryTitle)
                    .font(RewindFont.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rewindSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.rewindTextPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isRequesting)
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rewindBackground.ignoresSafeArea())
    }

    private var primaryTitle: String {
        if page == 3 { return isRequesting ? "Waiting…" : "Allow Photos Access" }
        return "Continue"
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Rewind")
                .font(RewindFont.caption)
                .foregroundStyle(Color.rewindTextSecondary)
                .textCase(.uppercase)
                .tracking(1.4)
            Text("Rediscover your photos.\nFree up space along the way.")
                .font(RewindFont.title)
                .foregroundStyle(Color.rewindTextPrimary)
                .multilineTextAlignment(.center)
            Text("A short tour, then your first deck.")
                .font(RewindFont.body)
                .foregroundStyle(Color.rewindTextSecondary)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var gestures: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Four directions.")
                .font(RewindFont.title)
                .foregroundStyle(Color.rewindTextPrimary)
            VStack(spacing: 18) {
                directionRow("arrow.up", title: "Up", detail: "Delete — staged first")
                directionRow("arrow.right", title: "Right", detail: "Keep as a favorite")
                directionRow("arrow.left", title: "Left", detail: "Skip for now")
                directionRow("arrow.down", title: "Down", detail: "Save for later")
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var previewHint: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 36, weight: .medium))
                .symbolVariant(.none)
                .foregroundStyle(Color.rewindTextPrimary)
            Text("Pinch to look closer.")
                .font(RewindFont.title)
                .foregroundStyle(Color.rewindTextPrimary)
                .multilineTextAlignment(.center)
            Text("Pinch out on a card to preview the full photo, screenshot, or video with sound. Pinch in to close.")
                .font(RewindFont.body)
                .foregroundStyle(Color.rewindTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var permission: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Your library stays on this phone.")
                .font(RewindFont.title)
                .foregroundStyle(Color.rewindTextPrimary)
                .multilineTextAlignment(.center)
            Text("Rewind reads photos on-device. Nothing is uploaded. Deleted items go to a staging bin first, then iOS Recently Deleted.")
                .font(RewindFont.body)
                .foregroundStyle(Color.rewindTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func directionRow(_ icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .symbolVariant(.none)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RewindFont.body)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(RewindFont.caption)
                    .foregroundStyle(Color.rewindTextSecondary)
            }
            Spacer()
        }
        .foregroundStyle(Color.rewindTextPrimary)
    }

    private func advance() {
        if page < 3 {
            withAnimation(RewindSpring.standard) { page += 1 }
            return
        }
        isRequesting = true
        Task {
            _ = await photos.requestAuthorization()
            isRequesting = false
            onFinished()
        }
    }
}
