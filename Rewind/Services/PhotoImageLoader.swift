import Foundation
import Photos
import UIKit

final class PhotoImageLoader {
    static let shared = PhotoImageLoader()

    enum Quality {
        case deck
        case preview
    }

    let manager = PHCachingImageManager()
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 60
        manager.allowsCachingHighQualityImages = true
    }

    func cached(asset: PHAsset, size: CGSize, quality: Quality) -> UIImage? {
        cache.object(forKey: key(asset: asset, size: size, quality: quality))
    }

    func request(
        asset: PHAsset,
        size: CGSize,
        quality: Quality = .deck,
        contentMode: PHImageContentMode = .aspectFill,
        resultHandler: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let cacheKey = key(asset: asset, size: size, quality: quality)
        if let cached = cache.object(forKey: cacheKey) {
            resultHandler(cached)
            return PHInvalidImageRequestID
        }

        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        switch quality {
        case .deck:
            options.deliveryMode = .opportunistic
        case .preview:
            options.deliveryMode = .highQualityFormat
        }

        return manager.requestImage(
            for: asset,
            targetSize: pixelSize(for: size),
            contentMode: contentMode,
            options: options
        ) { [weak self] image, info in
            let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
            guard !cancelled, let image else { return }
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if !degraded {
                self?.cache.setObject(image, forKey: cacheKey)
            }
            DispatchQueue.main.async {
                resultHandler(image)
            }
        }
    }

    func cancel(_ requestID: PHImageRequestID) {
        guard requestID != PHInvalidImageRequestID else { return }
        manager.cancelImageRequest(requestID)
    }

    func prefetch(assets: [PHAsset], size: CGSize) {
        guard !assets.isEmpty else { return }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        manager.startCachingImages(
            for: assets,
            targetSize: pixelSize(for: size),
            contentMode: .aspectFill,
            options: options
        )
    }

    func stopPrefetch(assets: [PHAsset], size: CGSize) {
        guard !assets.isEmpty else { return }
        manager.stopCachingImages(
            for: assets,
            targetSize: pixelSize(for: size),
            contentMode: .aspectFill,
            options: nil
        )
    }

    private func key(asset: PHAsset, size: CGSize, quality: Quality) -> NSString {
        let width = Int(size.width.rounded())
        let height = Int(size.height.rounded())
        return "\(asset.localIdentifier)-\(width)x\(height)-\(quality == .preview ? "p" : "d")" as NSString
    }

    private func pixelSize(for size: CGSize) -> CGSize {
        let scale = UITraitCollection.current.displayScale
        return CGSize(
            width: (max(size.width, 1) * scale).rounded(),
            height: (max(size.height, 1) * scale).rounded()
        )
    }
}
