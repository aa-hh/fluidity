import FluidAudio
import Foundation

/// `ModelFetching` over FluidAudio's model folders under Application Support. Untested: it needs real files and the network.
public struct FluidAudioModelFetcher: ModelFetching {
    public init() {}

    /// FluidAudio's `Application Support/FluidAudio/Models`, the parent of every model's own folder.
    private static var modelsDirectory: URL { AsrModels.defaultCacheDirectory(for: .v2).deletingLastPathComponent() }

    /// Where a downloadable model's files live; nil for Apple's model.
    public static func folder(of id: SpeechModelID) -> URL? {
        guard case .download(_, _, let folder) = SpeechModel.model(id).install else { return nil }
        return modelsDirectory.appendingPathComponent(folder, isDirectory: true)
    }

    public func isInstalled(_ id: SpeechModelID) -> Bool {
        switch id {
        case .appleBuiltIn:
            return true
        case .parakeetTDTv2:
            return AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: .v2), version: .v2)
        case .fluidSpeechPro:
            return SpeechModel.fluidSpeechProFiles.isInstalled(in: Self.folder(of: id)!)
        }
    }

    public func availableBytes() -> Int64 {
        freeBytes(onVolumeOf: Self.modelsDirectory)
    }

    public func download(_ id: SpeechModelID, progress: @escaping @Sendable (Double) -> Void) async throws {
        switch id {
        case .appleBuiltIn:
            return
        case .parakeetTDTv2:
            try await AsrModels.download(version: .v2) { progress($0.fractionCompleted) }
        case .fluidSpeechPro:
            try await SpeechModel.fluidSpeechProFiles.install(into: Self.folder(of: id)!, progress: progress)
        }
    }

    public func removeFiles(for id: SpeechModelID) throws {
        guard let url = Self.folder(of: id), FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}
