import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messagesList
            Divider()
            inputBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { inputFocused = true }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.circle.fill")
                .font(.title3)
                .foregroundStyle(.tint)
            Text("Pickaboo")
                .font(.headline)
            Spacer()
            Button {
                viewModel.clear()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear conversation")
            .disabled(viewModel.messages.isEmpty && !viewModel.isStreaming)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if viewModel.messages.isEmpty && !viewModel.isStreaming {
                        emptyState
                    }
                    ForEach(viewModel.messages) { message in
                        bubble(for: message)
                            .id(message.id)
                    }
                    if viewModel.isStreaming {
                        streamingBubble
                            .id("streaming")
                    }
                }
                .padding(12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.streamingResponse) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ask me anything")
                .font(.headline)
            Text("Try: \"what's the weather?\", \"what reminders do I have?\", \"what time is it?\"")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 40)
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer(minLength: 40)
            }
        }
    }

    private var streamingBubble: some View {
        HStack(alignment: .top) {
            Text(viewModel.streamingResponse.isEmpty ? "…" : viewModel.streamingResponse)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer()
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask Pickaboo…", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .lineLimit(1...5)
                .onSubmit { viewModel.send() }
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                viewModel.send()
            } label: {
                Image(systemName: viewModel.isStreaming ? "circle.dotted" : "arrow.up.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isStreaming ||
                      viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(10)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if viewModel.isStreaming {
            proxy.scrollTo("streaming", anchor: .bottom)
        } else if let last = viewModel.messages.last {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}
