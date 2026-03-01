import Combine
import CoreLocation
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var useCurrentLocation: Bool
    @Published var manualLatitudeText: String
    @Published var manualLongitudeText: String

    @Published private(set) var effectiveLocation: GeoPoint
    @Published private(set) var locationName: String = ""
    @Published private(set) var snapshot: EdoTimeSnapshot?
    @Published private(set) var now: Date = Date()
    @Published private(set) var errorMessage: String?

    let locationService = LocationService()

    private let edoTimeService = EdoTimeService()
    private var cancellables = Set<AnyCancellable>()

    private enum DefaultsKey {
        static let useCurrentLocation = "useCurrentLocation"
        static let manualLatitude = "manualLatitude"
        static let manualLongitude = "manualLongitude"
    }

    init() {
        let defaults = UserDefaults.standard
        let defaultTokyo = GeoPoint(latitude: 35.681236, longitude: 139.767125)

        let savedUseCurrent = defaults.object(forKey: DefaultsKey.useCurrentLocation) as? Bool ?? true
        let savedLat = defaults.object(forKey: DefaultsKey.manualLatitude) as? Double ?? defaultTokyo.latitude
        let savedLon = defaults.object(forKey: DefaultsKey.manualLongitude) as? Double ?? defaultTokyo.longitude

        self.useCurrentLocation = savedUseCurrent
        self.manualLatitudeText = String(format: "%.6f", savedLat)
        self.manualLongitudeText = String(format: "%.6f", savedLon)
        self.effectiveLocation = GeoPoint(latitude: savedLat, longitude: savedLon)

        bind()

        locationService.requestAuthorizationIfNeeded()
        if useCurrentLocation {
            locationService.refreshLocation()
        }
        recompute()
    }

    var sunriseText: String {
        guard let s = snapshot?.solarTimes.sunrise else { return "--:--" }
        return TimeText.hhmm(s)
    }

    var sunsetText: String {
        guard let s = snapshot?.solarTimes.sunset else { return "--:--" }
        return TimeText.hhmm(s)
    }

    var currentSegmentLabel: String {
        snapshot?.currentSegment.label ?? "計算待ち"
    }

    var remainingText: String {
        guard let snapshot else { return "--:--" }
        return TimeText.remaining(snapshot.remainingToNextBoundary)
    }

    var dayKokuText: String {
        guard let snapshot else { return "--" }
        return TimeText.minutes(snapshot.dayKoku)
    }

    var nightKokuText: String {
        guard let snapshot else { return "--" }
        return TimeText.minutes(snapshot.nightKoku)
    }

    func saveManualLocation() {
        guard
            let lat = Double(manualLatitudeText),
            let lon = Double(manualLongitudeText),
            (-90.0...90.0).contains(lat),
            (-180.0...180.0).contains(lon)
        else {
            errorMessage = "緯度経度の入力が不正です。"
            return
        }

        let point = GeoPoint(latitude: lat, longitude: lon)
        let defaults = UserDefaults.standard
        defaults.set(lat, forKey: DefaultsKey.manualLatitude)
        defaults.set(lon, forKey: DefaultsKey.manualLongitude)

        effectiveLocation = point
        locationName = "手動地点"
        errorMessage = nil
        recompute()
    }

    func refreshLocation() {
        locationService.refreshLocation()
    }

    private func bind() {
        $useCurrentLocation
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self else { return }
                UserDefaults.standard.set(newValue, forKey: DefaultsKey.useCurrentLocation)
                if newValue {
                    locationService.refreshLocation()
                } else {
                    saveManualLocation()
                }
                recompute()
            }
            .store(in: &cancellables)

        locationService.$coordinate
            .sink { [weak self] coordinate in
                guard let self else { return }
                guard useCurrentLocation else { return }
                if let coordinate {
                    effectiveLocation = coordinate
                    errorMessage = nil
                    recompute()
                }
            }
            .store(in: &cancellables)

        locationService.$placeName
            .sink { [weak self] name in
                guard let self else { return }
                if useCurrentLocation {
                    locationName = name ?? "現在地"
                }
            }
            .store(in: &cancellables)

        locationService.$errorMessage
            .sink { [weak self] message in
                guard let self else { return }
                if useCurrentLocation, let message {
                    errorMessage = message
                }
            }
            .store(in: &cancellables)

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                now = date
                recompute()
            }
            .store(in: &cancellables)
    }

    private func recompute() {
        now = Date()

        if useCurrentLocation == false {
            if let lat = Double(manualLatitudeText), let lon = Double(manualLongitudeText) {
                effectiveLocation = GeoPoint(latitude: lat, longitude: lon)
                locationName = "手動地点"
            }
        } else if locationService.coordinate == nil {
            // Timeline-first: keep UI renderable using manual/default fallback.
            locationName = "手動地点(フォールバック)"
        }

        do {
            snapshot = try edoTimeService.compute(now: now, location: effectiveLocation)
            errorMessage = nil
        } catch {
            snapshot = nil
            errorMessage = error.localizedDescription
        }
    }
}
