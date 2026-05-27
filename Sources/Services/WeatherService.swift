import Combine
import CoreLocation
import Foundation

final class WeatherService: ObservableObject {
    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var lastError: String?

    private let locationService: LocationService
    private let session: URLSession = .shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    private let refreshInterval: TimeInterval = 30 * 60
    private let endpoint = "https://api.open-meteo.com/v1/forecast"

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func start() {
        locationService.$location
            .compactMap { $0 }
            .removeDuplicates { previous, next in
                abs(previous.coordinate.latitude - next.coordinate.latitude) < 0.01 &&
                abs(previous.coordinate.longitude - next.coordinate.longitude) < 0.01
            }
            .sink { [weak self] location in
                self?.fetch(for: location.coordinate)
            }
            .store(in: &cancellables)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }

        locationService.start()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
    }

    func refresh() {
        locationService.refresh()
        if let existing = locationService.location {
            fetch(for: existing.coordinate)
        }
    }

    private func fetch(for coordinate: CLLocationCoordinate2D) {
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: "celsius")
        ]
        guard let url = components.url else { return }

        session.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async { self.lastError = error.localizedDescription }
                return
            }
            guard let data else {
                DispatchQueue.main.async { self.lastError = "No data" }
                return
            }

            do {
                let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                let snapshot = WeatherSnapshot(
                    temperatureCelsius: response.current.temperature_2m,
                    weatherCode: response.current.weather_code,
                    updatedAt: Date()
                )
                DispatchQueue.main.async {
                    self.snapshot = snapshot
                    self.lastError = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = "Decode failed"
                }
            }
        }.resume()
    }

    private struct OpenMeteoResponse: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let weather_code: Int
        }
        let current: Current
    }
}
