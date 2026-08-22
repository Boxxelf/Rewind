import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case clean
    case explore
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: "Clean"
        case .explore: "Explore"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .clean: "rectangle.stack"
        case .explore: "map"
        case .profile: "person"
        }
    }
}

struct RootView: View {
    @State private var tab: AppTab = .clean

    var body: some View {
        ZStack {
            Color.rewindBackground.ignoresSafeArea()

            CleanTabView()
                .opacity(tab == .clean ? 1 : 0)
                .allowsHitTesting(tab == .clean)

            if tab == .explore {
                ExploreTabView(isActive: true)
            }

            if tab == .profile {
                ProfileTabView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $tab)
                .padding(.horizontal, 36)
                .padding(.bottom, 10)
        }
        .fontDesign(.rounded)
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(RewindSpring.snappy) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .symbolVariant(.none)
                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(
                        selection == tab ? Color.rewindTextPrimary : Color.rewindTextSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.rewindBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
    }
}
