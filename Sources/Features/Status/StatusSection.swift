import SwiftUI

struct StatusSection: View {
    @ObservedObject var weather: WeatherService
    @ObservedObject var location: LocationService

    @State private var now: Date = Date()
    private let clockTick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            clockView
            Divider().frame(height: 36)
            weatherView
            Spacer(minLength: 0)
        }
        .onReceive(clockTick) { now = $0 }
    }

    private var clockView: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(now, format: .dateTime.hour().minute())
                .font(.title2.monospacedDigit())
            Text(now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var weatherView: some View {
        switch (location.access, weather.snapshot) {
        case (.granted, .some(let snapshot)):
            HStack(spacing: 10) {
                Image(systemName: snapshot.symbolName)
                    .font(.title2)
                    .symbolRenderingMode(.multicolor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(formattedTemperature(snapshot.temperatureCelsius))
                        .font(.title3.monospacedDigit())
                    Text(snapshot.conditionDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

        case (.unknown, _):
            Button {
                location.requestAccess()
            } label: {
                Label("Enable weather", systemImage: "location.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)

        case (.denied, _):
            VStack(alignment: .leading, spacing: 2) {
                Text("Location denied")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Enable in System Settings → Privacy → Location, then relaunch.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case (.granted, .none):
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(weather.lastError ?? "Fetching weather…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formattedTemperature(_ celsius: Double) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        return measurement.formatted(
            .measurement(width: .narrow, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))
        )
    }
}
