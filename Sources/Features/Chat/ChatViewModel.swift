import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var input: String = ""
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var streamingResponse: String = ""

    private let aiService: AIService
    private let contextProvider: () -> AssistantContext
    private var currentTask: Task<Void, Never>?

    init(aiService: AIService, contextProvider: @escaping () -> AssistantContext) {
        self.aiService = aiService
        self.contextProvider = contextProvider
    }

    func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        input = ""

        let context = contextProvider()
        let conversation = messages

        isStreaming = true
        streamingResponse = ""

        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }
            var buffer = ""
            for await chunk in self.aiService.send(conversation, context: context) {
                if Task.isCancelled { break }
                buffer += chunk
                self.streamingResponse = buffer
            }
            if !Task.isCancelled {
                self.messages.append(ChatMessage(role: .assistant, content: buffer))
            }
            self.streamingResponse = ""
            self.isStreaming = false
        }
    }

    func clear() {
        currentTask?.cancel()
        messages.removeAll()
        streamingResponse = ""
        isStreaming = false
    }
}
