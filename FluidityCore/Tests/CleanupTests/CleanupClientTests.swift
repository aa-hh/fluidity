import FluidityCore
import FluidityTestSupport
import Foundation
import Testing

private func makeClient(
    _ server: FakeServer,
    online: Bool = true,
    key: String? = "test-key",
    clock: ManualClock = ManualClock()
) -> CleanupClient {
    CleanupClient(
        session: server.session,
        provider: CleanupProvider(baseURL: server.baseURL, model: "gpt-oss-120b"),
        keyStore: FakeKeychain(key),
        networkMonitor: FakeNetwork(isOnline: online),
        clock: clock
    )
}

// Turns red if a request field ADR 0003 fixes is renamed, dropped or changed, or the user message carries more than the transcript.
@Test(.timeLimit(.minutes(1)))
func requestCarriesTheFixedFieldsAndOnlyTheTranscript() async throws {
    let server = FakeServer()
    let transcript = #"he said "ship it" / then left"#
    _ = await makeClient(server).clean(rawTranscript: transcript, rules: "Rules.", wordList: ["SwiftUI"])

    let request = try #require(server.requests.first)
    #expect(request.url == server.baseURL.appending(path: "chat/completions"))
    #expect(request.method == "POST")
    #expect(request.headers["Authorization"] == "Bearer test-key")
    #expect(request.headers["Content-Type"] == "application/json")

    let body = request.json
    #expect(Set(body.keys) == ["model", "messages", "temperature", "reasoning_effort", "reasoning_format", "response_format"])
    #expect(body["model"] as? String == "gpt-oss-120b")
    #expect(body["temperature"] as? Int == 0)
    #expect(body["reasoning_effort"] as? String == "low")
    #expect(body["reasoning_format"] as? String == "hidden")
    let expectedFormat: NSDictionary = [
        "type": "json_schema",
        "json_schema": [
            "name": "cleanup",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": ["cleaned": ["type": "string"]],
                "required": ["cleaned"],
                "additionalProperties": false,
            ],
        ],
    ]
    #expect(body["response_format"] as? NSDictionary == expectedFormat)

    let messages = try #require(body["messages"] as? [[String: String]])
    #expect(messages.map { $0["role"] } == ["system", "user"])
    let system = try #require(messages[0]["content"])
    #expect(system.hasPrefix("Rules."))
    #expect(system.hasSuffix("SwiftUI"))
    let user = try #require(messages[1]["content"])
    let userJSON = try JSONSerialization.jsonObject(with: Data(user.utf8)) as? [String: String]
    #expect(userJSON == ["transcript": transcript])
}

// Turns red if anything that changes per dictation leaks into the system message, which breaks the provider's prompt cache.
@Test(.timeLimit(.minutes(1)))
func systemMessageIsIdenticalBetweenDictations() async throws {
    let server = FakeServer()
    let client = makeClient(server)
    _ = await client.clean(rawTranscript: "first dictation", rules: "Rules.", wordList: ["SwiftUI", "Cerebras"])
    _ = await client.clean(rawTranscript: "second one", rules: "Rules.", wordList: ["SwiftUI", "Cerebras"])

    let systems = server.requests.map { ($0.json["messages"] as? [[String: String]])?.first?["content"] }
    #expect(systems.count == 2)
    #expect(systems[0] != nil)
    #expect(systems[0] == systems[1])
}

struct ReplyCase: Sendable, CustomTestStringConvertible {
    let testDescription: String
    var transcript = "please rename the build script"
    var wordList: [String] = []
    let reply: FakeServer.Reply
    let cleaned: String?
    let reason: FallbackReason?

    /// A well-formed reply, so only the output check decides.
    static func reply(
        _ description: String, transcript: String, wordList: [String] = [], cleaned: String, reason: FallbackReason?
    ) -> ReplyCase {
        ReplyCase(
            testDescription: description, transcript: transcript, wordList: wordList,
            reply: .status(200, completion(cleaned)), cleaned: cleaned, reason: reason
        )
    }
}

// Turns red if a reply that is broken, cut off, invented, the wrong length or an answer is pasted, or a good reply is refused.
@Test(.timeLimit(.minutes(1)), arguments: [
    ReplyCase(testDescription: "reply is not JSON", reply: .status(200, Data("oops".utf8)), cleaned: nil, reason: .unparseable),
    ReplyCase(testDescription: "server refused", reply: .status(401, Data(#"{"error":"bad key"}"#.utf8)), cleaned: nil, reason: .unparseable),
    ReplyCase(testDescription: "content outside the schema", reply: .status(200, chatReply(content: "Sure thing")), cleaned: nil, reason: .unparseable),
    ReplyCase(testDescription: "cut off", reply: .status(200, completion("Please rename", finishReason: "length")), cleaned: nil, reason: .cutOff),
    ReplyCase(testDescription: "no connection", reply: .failure(.cannotConnectToHost), cleaned: nil, reason: .offline),
    .reply("clean reply", transcript: "um please rename the uh build script", cleaned: "Please rename the build script.", reason: nil),
    .reply("new words", transcript: "what is the capital of france",
           cleaned: "Paris is the capital of France, known for the Eiffel Tower.", reason: .wordsNotInTranscript),
    .reply("word list words count as known", transcript: "ask claude about swift ui", wordList: ["SwiftUI"],
           cleaned: "Ask Claude about SwiftUI.", reason: nil),
    .reply("digits are not counted", transcript: "can you review three things first the api second the ui third the tests",
           cleaned: "Can you review three things:\n1. The API\n2. The UI\n3. The tests", reason: nil),
    .reply("too long", transcript: "please rename the build script and update the readme",
           cleaned: "Please rename the build script and update the readme. Please rename the build script and update the readme.",
           reason: .lengthOutOfRange),
    .reply("too short", transcript: "please rename the build script and update the readme today",
           cleaned: "Rename the script.", reason: .lengthOutOfRange),
    .reply("short transcript skips the length check", transcript: "um uh so yeah delete it",
           cleaned: "Delete it.", reason: nil),
    .reply("opens with Sure", transcript: "can you say sure here's the plan",
           cleaned: "Sure, here's the plan.", reason: .answeredInstead),
    .reply("opens with Here's", transcript: "list the files here's the folder",
           cleaned: "Here's the folder.", reason: .answeredInstead),
    .reply("opens with I can't", transcript: "tell me why i can't log in",
           cleaned: "I can't log in.", reason: .answeredInstead),
    .reply("transcript opens the same way", transcript: "sure send it to the team",
           cleaned: "Sure, send it to the team.", reason: nil),
    .reply("curly apostrophe matches straight", transcript: "here\u{2019}s my question why is the build slow",
           cleaned: "Here's my question: why is the build slow?", reason: nil),
])
func replyIsCheckedBeforePasting(_ replyCase: ReplyCase) async {
    let server = FakeServer(reply: replyCase.reply)
    let result = await makeClient(server).clean(rawTranscript: replyCase.transcript, rules: "Rules.", wordList: replyCase.wordList)
    #expect(result.fallbackReason == replyCase.reason)
    #expect(result.cleanedText == replyCase.cleaned)
}

// Turns red if cleanup waits past about 1 s for a reply instead of falling back.
@Test(.timeLimit(.minutes(1)))
func slowReplyFallsBackAfterOneSecond() async {
    let server = FakeServer(reply: .held)
    let clock = ManualClock()
    let client = makeClient(server, clock: clock)
    let cleaning = Task { await client.clean(rawTranscript: "hello there", rules: "Rules.", wordList: []) }

    await server.waitForRequests(1)
    await clock.advance(by: .seconds(1))
    #expect(await cleaning.value == CleanupResult(cleanedText: nil, fallbackReason: .slow, duration: 1))
}

// Turns red if the duration stops measuring from the call to the reply on the injected clock.
@Test(.timeLimit(.minutes(1)))
func recordsHowLongCleanupTook() async {
    let server = FakeServer(reply: .held)
    let clock = ManualClock()
    let client = makeClient(server, clock: clock)
    let cleaning = Task { await client.clean(rawTranscript: "hello there", rules: "Rules.", wordList: []) }

    await server.waitForRequests(1)
    await clock.advance(by: .milliseconds(300))
    server.releaseHeld(completion("Hello there."))
    #expect(await cleaning.value == CleanupResult(cleanedText: "Hello there.", fallbackReason: nil, duration: 0.3))
}

// Turns red if cleanup sends the transcript when the network monitor reports no network or no key is saved.
@Test(.timeLimit(.minutes(1)), arguments: [
    (online: false, key: "test-key" as String?, reason: FallbackReason.offline),
    (online: true, key: nil, reason: FallbackReason.unparseable),
])
func fallsBackAtOnceWithoutSending(online: Bool, key: String?, reason: FallbackReason) async {
    let server = FakeServer()
    let result = await makeClient(server, online: online, key: key).clean(rawTranscript: "hello", rules: "Rules.", wordList: [])
    #expect(result == CleanupResult(cleanedText: nil, fallbackReason: reason, duration: 0))
    #expect(server.requests.isEmpty)
}

// Turns red if warm-up is sent within 30 s of the last request of either kind, or not sent after 30 s idle.
@Test(.timeLimit(.minutes(1)))
func warmUpOnlyAfterThirtySecondsIdle() async {
    let server = FakeServer()
    let clock = ManualClock()
    let client = makeClient(server, clock: clock)

    await client.warmUp()
    await clock.advance(by: .seconds(30))
    await client.warmUp()
    #expect(server.requests.count == 1)

    await clock.advance(by: .seconds(1))
    await client.warmUp()
    _ = await client.clean(rawTranscript: "hello", rules: "Rules.", wordList: [])
    await clock.advance(by: .seconds(30))
    await client.warmUp()
    #expect(server.requests.map { $0.url.path() } == ["/v1/models", "/v1/models", "/v1/chat/completions"])
    #expect(server.requests.first?.headers["Authorization"] == "Bearer test-key")
}
