import FluidityCore
import Foundation
import Synchronization

struct FakeNetwork: NetworkMonitoring {
    var isOnline = true
}

final class FakeKeychain: KeychainStoring {
    private let value: Mutex<String?>

    init(_ value: String? = nil) { self.value = Mutex(value) }

    func get() -> String? { value.withLock { $0 } }
    func set(_ newValue: String) { value.withLock { $0 = newValue } }
    func delete() { value.withLock { $0 = nil } }
}

/// A chat completion whose content is the cleanup schema's JSON.
func completion(_ cleaned: String, finishReason: String = "stop") -> Data {
    let content = String(decoding: try! JSONSerialization.data(withJSONObject: ["cleaned": cleaned]), as: UTF8.self)
    return chatReply(content: content, finishReason: finishReason)
}

func chatReply(content: String, finishReason: String = "stop") -> Data {
    let reply: [String: Any] = [
        "choices": [["message": ["role": "assistant", "content": content], "finish_reason": finishReason]],
    ]
    return try! JSONSerialization.data(withJSONObject: reply)
}

/// A server reached through `URLProtocol`, one per test: each gets its own host, so tests
/// running in parallel never see each other's requests.
final class FakeServer: @unchecked Sendable {
    enum Reply: Sendable {
        case status(Int, Data)
        /// Never answered until `releaseHeld` is called.
        case held
        case failure(URLError.Code)
    }

    struct Request: Sendable {
        let url: URL
        let method: String
        let headers: [String: String]
        let body: Data

        var json: [String: Any] {
            (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
        }
    }

    private static let servers = Mutex<[String: FakeServer]>([:])

    let baseURL: URL
    let session: URLSession
    private let lock = NSLock()
    private let reply: Reply
    private var received: [Request] = []
    private var waiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var held: FakeURLProtocol?

    init(reply: Reply = .status(200, completion("Hello there."))) {
        let host = "\(UUID().uuidString.lowercased()).test"
        baseURL = URL(string: "https://\(host)/v1")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FakeURLProtocol.self]
        session = URLSession(configuration: configuration)
        self.reply = reply
        Self.servers.withLock { $0[host] = self }
    }

    static func server(for host: String?) -> FakeServer? {
        servers.withLock { servers in host.flatMap { servers[$0] } }
    }

    var requests: [Request] { lock.withLock { received } }

    func waitForRequests(_ count: Int) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let ready = lock.withLock {
                if received.count >= count { return true }
                waiters.append((count, continuation))
                return false
            }
            if ready { continuation.resume() }
        }
    }

    func releaseHeld(_ body: Data) {
        lock.withLock { held }?.respond(status: 200, body: body)
    }

    fileprivate func receive(_ request: Request, from loader: FakeURLProtocol) -> Reply {
        let ready: [CheckedContinuation<Void, Never>] = lock.withLock {
            received.append(request)
            if case .held = reply { held = loader }
            let ready = waiters.filter { $0.count <= received.count }.map(\.continuation)
            waiters.removeAll { $0.count <= received.count }
            return ready
        }
        ready.forEach { $0.resume() }
        return reply
    }
}

final class FakeURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let server = FakeServer.server(for: url.host()) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }
        let recorded = FakeServer.Request(
            url: url,
            method: request.httpMethod ?? "GET",
            headers: request.allHTTPHeaderFields ?? [:],
            body: request.httpBody ?? Self.read(request.httpBodyStream)
        )
        switch server.receive(recorded, from: self) {
        case let .status(code, body): respond(status: code, body: body)
        case let .failure(code): client?.urlProtocol(self, didFailWithError: URLError(code))
        case .held: break
        }
    }

    override func stopLoading() {}

    func respond(status: Int, body: Data) {
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    private static func read(_ stream: InputStream?) -> Data {
        guard let stream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while case let count = stream.read(&buffer, maxLength: buffer.count), count > 0 {
            data.append(buffer, count: count)
        }
        return data
    }
}
