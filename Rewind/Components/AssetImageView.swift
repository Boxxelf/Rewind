import Photos
import SwiftUI

struct AssetImageView: View {
    let asset: PHAsset
    var contentMode: ContentMode = .fill
    var quality: PhotoImageLoader.Quality = .deck
    var targetSize: CGSize? = nil

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?
    @State private var requestedSize: CGSize = .zero

    var body: some View {
        if let targetSize, targetSize.width > 1 {
            canvas(size: targetSize)
        } else {
            GeometryReader { geo in
                canvas(size: geo.size)
                    .onAppear { start(size: geo.size) }
                    .onChange(of: geo.size) { _, size in start(size: size) }
            }
        }
    }

    private func canvas(size: CGSize) -> some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .transaction { $0.animation = nil }
            } else {
                Color.rewindSurface
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            if targetSize != nil { start(size: size) }
        }
        .onChange(of: asset.localIdentifier) { _, _ in
            requestedSize = .zero
            image = PhotoImageLoader.shared.cached(asset: asset, size: size, quality: quality)
            start(size: size)
        }
        .accessibilityHidden(true)
    }

    private func start(size: CGSize) {
        let rounded = CGSize(width: size.width.rounded(), height: size.height.rounded())
        guard rounded.width > 1, rounded.height > 1 else { return }
        if abs(rounded.width - requestedSize.width) < 4,
           abs(rounded.height - requestedSize.height) < 4,
           image != nil {
            return
        }
        if let cached = PhotoImageLoader.shared.cached(asset: asset, size: rounded, quality: quality) {
            image = cached
            requestedSize = rounded
            return
        }
        requestedSize = rounded
        if let requestID {
            PhotoImageLoader.shared.cancel(requestID)
            self.requestID = nil
        }
        requestID = PhotoImageLoader.shared.request(asset: asset, size: rounded, quality: quality) { loaded in
            guard loaded != nil else { return }
            image = loaded
        }
    }
}
