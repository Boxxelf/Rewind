import Foundation
import Photos
import UIKit

@Observable
final class PhotoLibraryService: NSObject, PHPhotoLibraryChangeObserver {
    private(set) var authorizationStatus: PHAuthorizationStatus
    var libraryEpoch: Int = 0

    override init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    nonisolated deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func refreshStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status
    }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.libraryEpoch += 1
        }
    }

    nonisolated func fetchCandidates(in category: MediaCategory, excluding: Set<String>) -> [ShuffleCandidate] {
        Self.fetchCandidates(in: category, excluding: excluding)
    }

    nonisolated func count(in category: MediaCategory) -> Int {
        Self.count(in: category)
    }

    nonisolated func asset(for localIdentifier: String) -> PHAsset? {
        Self.asset(for: localIdentifier)
    }

    nonisolated func assets(for localIdentifiers: [String]) -> [PHAsset] {
        Self.assets(for: localIdentifiers)
    }

    nonisolated func byteSize(of asset: PHAsset) -> Int64 {
        Self.byteSize(of: asset)
    }

    nonisolated static func fetchCandidates(in category: MediaCategory, excluding: Set<String>) -> [ShuffleCandidate] {
        let options = PHFetchOptions()
        options.predicate = category.fetchPredicate
        options.includeHiddenAssets = false
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let result = PHAsset.fetchAssets(with: options)
        var candidates: [ShuffleCandidate] = []
        candidates.reserveCapacity(result.count)

        result.enumerateObjects { asset, _, _ in
            guard !excluding.contains(asset.localIdentifier) else { return }
            candidates.append(
                ShuffleCandidate(
                    id: asset.localIdentifier,
                    creationDate: asset.creationDate ?? .distantPast,
                    burstIdentifier: asset.burstIdentifier,
                    asset: asset
                )
            )
        }
        return candidates
    }

    nonisolated static func count(in category: MediaCategory) -> Int {
        let options = PHFetchOptions()
        options.predicate = category.fetchPredicate
        options.includeHiddenAssets = false
        return PHAsset.fetchAssets(with: options).count
    }

    nonisolated static func asset(for localIdentifier: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
    }

    nonisolated static func assets(for localIdentifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil)
        var items: [PHAsset] = []
        items.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            items.append(asset)
        }
        return items
    }

    nonisolated static func byteSize(of asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        let preferred = resources.filter {
            switch $0.type {
            case .photo, .video, .fullSizePhoto, .fullSizeVideo, .pairedVideo, .fullSizePairedVideo:
                true
            default:
                false
            }
        }
        let used = preferred.isEmpty ? resources : preferred
        return used.reduce(0) { partial, resource in
            let size = (resource.value(forKey: "fileSize") as? Int64)
                ?? (resource.value(forKey: "fileSize") as? NSNumber)?.int64Value
                ?? 0
            return partial + size
        }
    }

    func deleteAssets(identifiers: [String]) async throws {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        guard result.count > 0 else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(result)
        }
    }

    nonisolated static func assetsCreated(on day: Date, calendar: Calendar = .current) -> [PHAsset] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return fetchAssets(
            predicate: NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
        )
    }

    nonisolated static func onThisDayAssets(now: Date = .now, calendar: Calendar = .current) -> [PHAsset] {
        let comps = calendar.dateComponents([.month, .day], from: now)
        let thisYear = calendar.component(.year, from: now)
        var matches: [PHAsset] = []
        for year in (thisYear - 12)..<thisYear {
            var parts = DateComponents()
            parts.year = year
            parts.month = comps.month
            parts.day = comps.day
            if let date = calendar.date(from: parts) {
                matches.append(contentsOf: assetsCreated(on: date, calendar: calendar))
            }
        }
        return matches
    }

    nonisolated static func locatedAssets(limit: Int = 400) -> [PHAsset] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var items: [PHAsset] = []
        items.reserveCapacity(min(limit, result.count))
        result.enumerateObjects { asset, _, stop in
            if asset.location != nil {
                items.append(asset)
                if items.count >= limit {
                    stop.pointee = true
                }
            }
        }
        return items
    }

    nonisolated static func assets(inMonth month: Date, calendar: Calendar = .current) -> [PHAsset] {
        var parts = calendar.dateComponents([.year, .month], from: month)
        parts.day = 1
        guard let start = calendar.date(from: parts),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
        return fetchAssets(
            predicate: NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
        )
    }

    nonisolated static func fetchAssets(predicate: NSPredicate?) -> [PHAsset] {
        let options = PHFetchOptions()
        options.predicate = predicate
        options.includeHiddenAssets = false
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(with: options)
        var items: [PHAsset] = []
        items.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            items.append(asset)
        }
        return items
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
