import CoreLocation
import Foundation
import Photos

nonisolated struct TripCluster: Identifiable {
    var id: String { "\(latitude)-\(longitude)-\(startDate.timeIntervalSince1970)-\(assets.count)" }
    let title: String
    let latitude: Double
    let longitude: Double
    let startDate: Date
    let assets: [PHAsset]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum TripClusterer {
    static func clusters(from assets: [PHAsset]) -> [TripCluster] {
        let located = assets.compactMap { asset -> (PHAsset, CLLocation, Date)? in
            guard let location = asset.location, let date = asset.creationDate else { return nil }
            return (asset, location, date)
        }.sorted { $0.2 < $1.2 }

        guard !located.isEmpty else { return [] }

        var groups: [[(PHAsset, CLLocation, Date)]] = []
        var current: [(PHAsset, CLLocation, Date)] = [located[0]]

        for next in located.dropFirst() {
            let last = current[current.count - 1]
            let hours = abs(next.2.timeIntervalSince(last.2)) / 3600
            let km = next.1.distance(from: last.1) / 1000
            if hours <= 18, km <= 80 {
                current.append(next)
            } else {
                groups.append(current)
                current = [next]
            }
        }
        groups.append(current)

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return groups.compactMap { group in
            guard group.count >= 3, let first = group.first else { return nil }
            let center = CLLocation(
                latitude: group.map(\.1.coordinate.latitude).reduce(0, +) / Double(group.count),
                longitude: group.map(\.1.coordinate.longitude).reduce(0, +) / Double(group.count)
            )
            let title = "Trip · \(formatter.string(from: first.2)) · \(group.count) photos"
            return TripCluster(
                title: title,
                latitude: center.coordinate.latitude,
                longitude: center.coordinate.longitude,
                startDate: first.2,
                assets: group.map(\.0)
            )
        }
    }
}
