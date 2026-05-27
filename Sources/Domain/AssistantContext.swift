import Foundation

struct AssistantContext {
    let now: Date
    let weather: WeatherSnapshot?
    let upcomingReminders: [ReminderItem]

    static var empty: AssistantContext {
        AssistantContext(now: Date(), weather: nil, upcomingReminders: [])
    }
}
