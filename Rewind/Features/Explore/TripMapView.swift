import MapKit
import SwiftUI

final class TripAnnotation: NSObject, MKAnnotation {
    let trip: TripCluster
    var coordinate: CLLocationCoordinate2D { trip.coordinate }
    var title: String? { trip.title }

    init(trip: TripCluster) {
        self.trip = trip
    }
}

struct TripMapView: UIViewRepresentable {
    var trips: [TripCluster]
    var onSelect: (TripCluster) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.showsScale = false
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "trip")
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.tripsByID = Dictionary(uniqueKeysWithValues: trips.map { ($0.id, $0) })
        let existing = map.annotations.compactMap { $0 as? TripAnnotation }.map(\.trip.id)
        let incoming = Set(trips.map(\.id))
        if Set(existing) != incoming {
            map.removeAnnotations(map.annotations)
            map.addAnnotations(trips.map(TripAnnotation.init))
            if let first = trips.first {
                let region = MKCoordinateRegion(
                    center: first.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
                )
                map.setRegion(region, animated: false)
            }
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var onSelect: (TripCluster) -> Void
        var tripsByID: [String: TripCluster] = [:]

        init(onSelect: @escaping (TripCluster) -> Void) {
            self.onSelect = onSelect
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            if annotation is MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
                    for: annotation
                ) as? MKMarkerAnnotationView
                view?.markerTintColor = UIColor(Color.rewindTextPrimary)
                view?.glyphImage = UIImage(systemName: "photo.stack")
                return view
            }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "trip", for: annotation) as? MKMarkerAnnotationView
            view?.clusteringIdentifier = "rewind.trip"
            view?.markerTintColor = UIColor(Color.rewindTextPrimary)
            view?.glyphImage = UIImage(systemName: "photo")
            view?.canShowCallout = true
            view?.displayPriority = .defaultLow
            let button = UIButton(type: .system)
            button.setTitle("Clean this place", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            view?.rightCalloutAccessoryView = button
            return view
        }

        func mapView(
            _ mapView: MKMapView,
            annotationView view: MKAnnotationView,
            calloutAccessoryControlTapped control: UIControl
        ) {
            guard let annotation = view.annotation as? TripAnnotation else { return }
            onSelect(annotation.trip)
        }
    }
}
