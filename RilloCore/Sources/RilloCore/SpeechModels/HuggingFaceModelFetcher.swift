import CryptoKit
import Foundation

/// `ModelFetching` for cleanup models: each catalogue file over HTTPS from Hugging Face into
/// `Application Support/Rillo/CleanupModels/<id>/`. Untested: it needs real files and the network.
public struct HuggingFaceModelFetcher: ModelFetching {
    private static let root = URL.applicationSupportDirectory.appending(path: "Rillo/CleanupModels", directoryHint: .isDirectory)

    public init() {}

    private func folder(_ id: CleanupModelID) -> URL { Self.root.appending(path: id.rawValue, directoryHint: .isDirectory) }

    public func isInstalled(_ id: CleanupModelID) -> Bool { CleanupModel.model(id).source.isInstalled(in: folder(id)) }

    public func availableBytes() -> Int64 { freeBytes(onVolumeOf: Self.root) }

    public func download(_ id: CleanupModelID, progress: @escaping @Sendable (Double) -> Void) async throws {
        try await CleanupModel.model(id).source.install(into: folder(id), progress: progress)
    }

    public func removeFiles(for id: CleanupModelID) throws {
        let url = folder(id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}

/// A model's files, pinned to one commit of a Hugging Face repo, each with the size and SHA-256 a download must match.
public struct PinnedFiles: Sendable {
    public var repo: String
    public var revision: String
    /// Paths inside the repo, which may name subfolders.
    public var files: [(name: String, bytes: Int64, sha256: String)]

    public var totalBytes: Int64 { files.reduce(0) { $0 + $1.bytes } }

    public func url(of file: String) -> URL {
        URL(string: "https://huggingface.co/\(repo)/resolve/\(revision)/\(file)")!
    }

    /// Every file at its pinned size; checksums were checked when the download finished, not at each launch.
    func isInstalled(in folder: URL) -> Bool {
        files.allSatisfy { Self.size(of: folder.appending(path: $0.name)) == $0.bytes }
    }

    /// Downloads into a temporary folder on the same volume and moves it to `folder` only once every file matches,
    /// so a partial or damaged download never reads as installed.
    func install(into folder: URL, progress: @escaping @Sendable (Double) -> Void) async throws {
        let manager = FileManager.default
        let parent = folder.deletingLastPathComponent()
        try manager.createDirectory(at: parent, withIntermediateDirectories: true)
        let temporary = try manager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: parent, create: true)
        defer { try? manager.removeItem(at: temporary) }
        let total = Double(totalBytes)
        var finished: Int64 = 0
        for file in files {
            let destination = temporary.appending(path: file.name)
            try manager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            let before = finished
            try await FileDownload.run(url(of: file.name), to: destination) { written in
                progress(Double(before + written) / total)
            }
            guard Self.size(of: destination) == file.bytes, try Self.sha256(of: destination) == file.sha256 else {
                throw DamagedDownload(file: file.name)
            }
            finished += file.bytes
        }
        try Task.checkCancellation()
        if manager.fileExists(atPath: folder.path) { try manager.removeItem(at: folder) }
        try manager.moveItem(at: temporary, to: folder)
    }

    private static func size(of url: URL) -> Int64? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
    }

    private static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let chunk = try autoreleasepool { try handle.read(upToCount: 4 << 20) }
            guard let chunk, !chunk.isEmpty else { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

/// One file's download on its own session, reporting the bytes written so far as they arrive.
private final class FileDownload: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let destination: URL
    private let onBytes: @Sendable (Int64) -> Void
    // Set before the task resumes and read only by the session's delegate queue afterwards.
    private var continuation: CheckedContinuation<Void, any Error>?
    private var finishError: (any Error)?

    private init(destination: URL, onBytes: @escaping @Sendable (Int64) -> Void) {
        self.destination = destination
        self.onBytes = onBytes
    }

    static func run(_ url: URL, to destination: URL, onBytes: @escaping @Sendable (Int64) -> Void) async throws {
        try Task.checkCancellation()
        let delegate = FileDownload(destination: destination, onBytes: onBytes)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let task = session.downloadTask(with: url)
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                delegate.continuation = continuation
                task.resume()
            }
        } onCancel: {
            task.cancel()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        onBytes(totalBytesWritten)
    }

    /// The file at `location` is deleted when this returns, so it is moved here.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let status = (downloadTask.response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) else {
            finishError = URLError(.badServerResponse)
            return
        }
        do {
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            finishError = error
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error = error ?? finishError {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
        continuation = nil
    }
}
