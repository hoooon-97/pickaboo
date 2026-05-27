import Foundation

protocol AIService: AnyObject {
    /// Sends the full conversation and returns a stream of response chunks.
    /// Real implementations stream tokens from an LLM; the stub yields chunks of a canned reply.
    func send(_ messages: [ChatMessage], context: AssistantContext) -> AsyncStream<String>
}
