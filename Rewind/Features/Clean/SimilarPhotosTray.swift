import Photos
import SwiftUI

struct SimilarPhotosTray: View {
    let current: DeckItem
    var onKeepThisDeleteRest: () -> Void
    var onDismiss: () -> Void

    @State private var similarAssets: [PHAsset] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(current.similarIdentifiers.count + 1) similar")
                .font(RewindFont.caption)
                .foregroundStyle(Color.rewindTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    AssetImageView(asset: current.asset)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    ForEach(similarAssets, id: \.localIdentifier) { asset in
                        AssetImageView(asset: asset)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            Button(action: onKeepThisDeleteRest) {
                Text("Keep this, delete the rest")
                    .font(RewindFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rewindSurface)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.rewindTextPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.rewindTextSecondary)
                    .padding(8)
            }
            .buttonStyle(.plain),
            alignment: .topTrailing
        )
        .task(id: current.localIdentifier) {
            let ids = current.similarIdentifiers
            similarAssets = await Task.detached(priority: .utility) {
                var assets: [PHAsset] = []
                let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
                result.enumerateObjects { asset, _, _ in
                    assets.append(asset)
                }
                return assets
            }.value
        }
    }
}
