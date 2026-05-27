import Foundation

final class StubAIService: AIService {
    private let chunkSize = 6
    private let chunkDelayNanos: UInt64 = 30_000_000

    func send(_ messages: [ChatMessage], context: AssistantContext) -> AsyncStream<String> {
        let reply = generateReply(for: messages, context: context)
        return AsyncStream { continuation in
            Task {
                for chunk in chunks(of: reply, size: chunkSize) {
                    try? await Task.sleep(nanoseconds: chunkDelayNanos)
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }

    private func generateReply(for messages: [ChatMessage], context: AssistantContext) -> String {
        let lastUser = messages.last(where: { $0.role == .user })?.content.lowercased() ?? ""

        if lastUser.contains("weather") || lastUser.contains("temperature") {
            if let weather = context.weather {
                let temp = Int(weather.temperatureCelsius.rounded())
                return "Right now it's \(temp)°C and \(weather.conditionDescription.lowercased()). (Stub response — real LLM coming next.)"
            }
            return "Weather isn't available yet — make sure Location access is granted. (Stub response.)"
        }

        if lastUser.contains("time") || lastUser.contains("date") {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "It's \(formatter.string(from: context.now)). (Stub response.)"
        }

        if lastUser.contains("reminder") || lastUser.contains("todo") || lastUser.contains("task") {
            let items = context.upcomingReminders.prefix(3)
            if items.isEmpty {
                return "You have no reminders due in the next 7 days. (Stub response.)"
            }
            let bullets = items.map { "• \($0.title)" }.joined(separator: "\n")
            return "Here are your next \(items.count) reminder\(items.count == 1 ? "" : "s"):\n\(bullets)\n\n(Stub response — real LLM will summarise more naturally.)"
        }

        if lastUser.contains("hello") || lastUser.contains("hi") || lastUser.contains("hey") || lastUser.contains("안녕") {
            return "Hi! I'm Pickaboo, your stub assistant. Ask me about the weather, the time, or your reminders. A real LLM backend will replace me in the next stage."
        }

        if lastUser.isEmpty {
            return "I didn't catch that. Try asking about your day. (Stub response.)"
        }

        return "I'm a stub AI for now, so I can only respond to a few topics (weather, time, reminders). You said: \"\(lastUser)\". The real LLM is wired in next stage."
    }

    private func chunks(of string: String, size: Int) -> [String] {
        guard size > 0 else { return [string] }
        var result: [String] = []
        var index = string.startIndex
        while index < string.endIndex {
            let next = string.index(index, offsetBy: size, limitedBy: string.endIndex) ?? string.endIndex
            result.append(String(string[index..<next]))
            index = next
        }
        return result
    }
}
