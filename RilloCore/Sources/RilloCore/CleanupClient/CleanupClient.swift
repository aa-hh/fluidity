import Foundation

/// Where cleanup requests go: an OpenAI-format base URL and a model name.
public struct CleanupProvider: Sendable, Equatable {
    public var baseURL: URL
    public var model: String

    public init(baseURL: URL, model: String) {
        self.baseURL = baseURL
        self.model = model
    }

    public static let cerebras = CleanupProvider(baseURL: URL(string: "https://api.cerebras.ai/v1")!, model: "gpt-oss-120b")
}

/// What cleanup returned. When `fallbackReason` is set, the raw transcript is pasted instead;
/// `cleanedText` still holds any reply that failed the output check, so it can be saved.
public struct CleanupResult: Equatable, Sendable {
    public var cleanedText: String?
    public var fallbackReason: FallbackReason?
    /// Seconds from the call until the result was ready.
    public var duration: TimeInterval

    public init(cleanedText: String?, fallbackReason: FallbackReason?, duration: TimeInterval) {
        self.cleanedText = cleanedText
        self.fallbackReason = fallbackReason
        self.duration = duration
    }
}

/// Sends the raw transcript to the cleanup model and checks the reply before it can be pasted.
public actor CleanupClient {
    static let timeLimit = Duration.seconds(1)
    static let warmUpAfter = Duration.seconds(30)

    private let session: URLSession
    private let provider: CleanupProvider
    private let keyStore: any KeychainStoring
    private let networkMonitor: any NetworkMonitoring
    private let elapsed: @Sendable () -> Duration
    private let sleepUntil: @Sendable (Duration) async throws -> Void
    private var lastRequestAt: Duration?

    public init(
        session: URLSession,
        provider: CleanupProvider = .cerebras,
        keyStore: any KeychainStoring,
        networkMonitor: any NetworkMonitoring,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.session = session
        self.provider = provider
        self.keyStore = keyStore
        self.networkMonitor = networkMonitor
        let timing = Self.timing(clock)
        elapsed = timing.elapsed
        sleepUntil = timing.sleepUntil
    }

    /// Opens the connection at recording start when the last request was over 30 s ago.
    public func warmUp() async {
        let now = elapsed()
        if let lastRequestAt, now - lastRequestAt <= Self.warmUpAfter { return }
        guard let key = try? keyStore.get() else { return }
        lastRequestAt = now
        var request = URLRequest(url: provider.baseURL.appending(path: "models"))
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        _ = try? await session.data(for: request)
    }

    public func clean(rawTranscript: String, rules: String, wordList: [String]) async -> CleanupResult {
        let start = elapsed()
        func result(_ text: String?, _ reason: FallbackReason?) -> CleanupResult {
            CleanupResult(cleanedText: text, fallbackReason: reason, duration: Self.seconds(elapsed() - start))
        }
        guard networkMonitor.isOnline else { return result(nil, .offline) }
        // Without a key the request cannot succeed, so the transcript is never sent.
        guard let key = try? keyStore.get() else { return result(nil, .unparseable) }

        lastRequestAt = start
        let request = Self.request(provider: provider, key: key, rawTranscript: rawTranscript, rules: rules, wordList: wordList)
        enum Outcome: Sendable { case reply(Data, URLResponse), transportFailed, timedOut }
        let deadline = start + Self.timeLimit
        let outcome = await withTaskGroup(of: Outcome.self) { [session, sleepUntil] group in
            group.addTask {
                do {
                    let (data, response) = try await session.data(for: request)
                    return .reply(data, response)
                } catch {
                    return .transportFailed
                }
            }
            group.addTask {
                try? await sleepUntil(deadline)
                return .timedOut
            }
            let first = await group.next() ?? .timedOut
            group.cancelAll()
            return first
        }

        switch outcome {
        case .timedOut:
            return result(nil, .slow)
        case .transportFailed:
            return result(nil, .offline)
        case let .reply(data, response):
            switch Self.cleanedText(from: data, response: response) {
            case let .failure(fallback):
                return result(nil, fallback.reason)
            case let .success(cleaned):
                let reason = OutputCheck.fallbackReason(cleaned: cleaned, rawTranscript: rawTranscript, wordList: wordList)
                return result(cleaned, reason)
            }
        }
    }

    // MARK: Request

    static func request(provider: CleanupProvider, key: String, rawTranscript: String, rules: String, wordList: [String]) -> URLRequest {
        var request = URLRequest(url: provider.baseURL.appending(path: "chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": provider.model,
            "messages": [
                ["role": "system", "content": CleanupPrompt.systemMessage(rules: rules, wordList: wordList)],
                ["role": "user", "content": CleanupPrompt.json(["transcript": rawTranscript])],
            ],
            "temperature": 0,
            "reasoning_effort": "low",
            "reasoning_format": "hidden",
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "cleanup",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "properties": ["cleaned": ["type": "string"]],
                        "required": ["cleaned"],
                        "additionalProperties": false,
                    ] as [String: Any],
                ] as [String: Any],
            ] as [String: Any],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])
        return request
    }

    // MARK: Reply

    private struct Fallback: Error { let reason: FallbackReason }

    private struct ChatReply: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message
            let finish_reason: String?
        }
        let choices: [Choice]
    }

    private struct Cleaned: Decodable { let cleaned: String }

    private static func cleanedText(from data: Data, response: URLResponse) -> Result<String, Fallback> {
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let choice = (try? JSONDecoder().decode(ChatReply.self, from: data))?.choices.first
        else { return .failure(Fallback(reason: .unparseable)) }
        guard choice.finish_reason == "stop" else { return .failure(Fallback(reason: .cutOff)) }
        guard let content = choice.message.content,
              let cleaned = try? JSONDecoder().decode(Cleaned.self, from: Data(content.utf8))
        else { return .failure(Fallback(reason: .unparseable)) }
        return .success(cleaned.cleaned)
    }

    // MARK: Time

    private static func timing<C: Clock<Duration>>(
        _ clock: C
    ) -> (elapsed: @Sendable () -> Duration, sleepUntil: @Sendable (Duration) async throws -> Void) {
        let origin = clock.now
        return (
            { origin.duration(to: clock.now) },
            { try await clock.sleep(until: origin.advanced(by: $0), tolerance: nil) }
        )
    }

    private static func seconds(_ duration: Duration) -> TimeInterval {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
}
