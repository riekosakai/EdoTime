import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var coordinate: GeoPoint?
    @Published private(set) var placeName: String?
    @Published private(set) var errorMessage: String?

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()

    override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var locationAvailable: Bool {
        coordinate != nil
    }

    func requestAuthorizationIfNeeded() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func refreshLocation() {
        errorMessage = nil
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "位置情報が許可されていません。手動入力を利用してください。"
        @unknown default:
            errorMessage = "位置情報の状態を確認できません。"
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let name = placemarks?.first.map {
                [$0.locality, $0.subLocality, $0.name]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
            Task { @MainActor in
                self.placeName = name?.isEmpty == false ? name : nil
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            coordinate = GeoPoint(latitude: latest.coordinate.latitude, longitude: latest.coordinate.longitude)
            placeName = nil
            reverseGeocode(latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.errorMessage = "位置情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }
}
