import Combine
import CoreLocation

enum LocationAccess: Equatable {
    case unknown
    case granted
    case denied
}

final class LocationService: NSObject, ObservableObject {
    @Published private(set) var location: CLLocation?
    @Published private(set) var access: LocationAccess = .unknown

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        refreshAccess()
    }

    func start() {
        refreshAccess()
        switch access {
        case .granted:
            manager.requestLocation()
        case .unknown:
            manager.requestWhenInUseAuthorization()
        case .denied:
            break
        }
    }

    func requestAccess() {
        manager.requestWhenInUseAuthorization()
    }

    func refresh() {
        guard access == .granted else { return }
        manager.requestLocation()
    }

    private func refreshAccess() {
        switch manager.authorizationStatus {
        case .authorized, .authorizedAlways:
            access = .granted
        case .denied, .restricted:
            access = .denied
        case .notDetermined:
            access = .unknown
        @unknown default:
            access = .unknown
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshAccess()
        if access == .granted {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.location = last
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // ignore; refresh() retries on next tick or auth change
    }
}
