import Foundation

/// The local cleanup models Rillo can download. Raw values may be saved in records, so never rename them.
public enum CleanupModelID: String, Codable, CaseIterable, Sendable {
    case rilloCleanup2B = "rillo-cleanup-2b"
    case s1Mini = "s1-mini-mlx"
}

/// One row of the cleanup model catalogue: where its files come from and what the settings pane shows about it.
public struct CleanupModel: Sendable, Identifiable {
    public var id: CleanupModelID
    public var name: String
    /// The Hugging Face repo and the commit its files are pinned to.
    public var repo: String
    public var revision: String
    /// Every file the model needs, with the size and SHA-256 a download must match.
    public var files: [(name: String, bytes: Int64, sha256: String)]
    /// Measured on an Apple M1; nil when not measured.
    public var secondsPerDictation: Double?
    public var memoryGB: Double?
    public var usesWordList: Bool

    public var totalBytes: Int64 { files.reduce(0) { $0 + $1.bytes } }

    public func url(of file: String) -> URL {
        URL(string: "https://huggingface.co/\(repo)/resolve/\(revision)/\(file)")!
    }

    public static let all: [CleanupModel] = [
        CleanupModel(
            id: .rilloCleanup2B, name: "Qwen3.5 2B, tuned for dictation",
            repo: "rillotalk/rillo-cleanup-2b", revision: "b749a9d1086af0002593d49b61677cd830772a8d",
            files: [
                ("model.safetensors", 1_280_110_602, "81ef41b86017af5c6691616e6cea2b0e4ba8f367bdb648c3c9acb608ca8ba27e"),
                ("config.json", 2364, "17d8df7f28fe1c80fa15fbe25f0e6e83d6d88945d8e76dc3033df838885d4ec4"),
                ("generation_config.json", 160, "9eb5c5bbcd23c2efeeaa6535a56c9474f689399fddc7a5c3a3143a404e53f7cf"),
                ("tokenizer.json", 3_404_620, "ed0d2c23267bfc3179ffcde662d961d88e4bb6d762d8f0e5bbee7c4d50f171f4"),
                ("tokenizer_config.json", 1502, "4d2fc7899270dc76b57a7aa1d5ec3234e6a25934c6e2aea6166f989f1d453892"),
                ("chat_template.jinja", 7755, "273d8e0e683b885071fb17e08d71e5f2a5ddfb5309756181681de4f5a1822d80"),
            ],
            secondsPerDictation: 1.2, memoryGB: 1.6, usesWordList: true),
        // Its licence requires the names "S1-mini" and "Superwhisper" exactly as written here.
        CleanupModel(
            id: .s1Mini, name: "S1-mini by Superwhisper",
            repo: "rillotalk/S1-mini-mlx", revision: "70dfc7da157101f4e43de68e2a07471e13b0e3b1",
            files: [
                ("model.safetensors", 439_825_323, "8093298f7a990023fe7cc9cd89f08cab7725a60e21a652edc51b02351b403ee8"),
                ("config.json", 917, "8ff1e29a68d17766c3e9c859c2a4c774a03a5d075a4964f89117b38c2e208e0e"),
                ("generation_config.json", 156, "4156c81cdbe9134ac80a8723b3a3d316bc217e35b17522dfbe2f7f67f2c2915b"),
                ("tokenizer.json", 3_459_982, "c6aa28b573de6b04c6acb5ebbd2073b3564e21859aa65f96b24469b3674e6979"),
                ("tokenizer_config.json", 728, "b001d07c42c37b2844dc8867fcf8b0ecf7cddfe529e74dc593ea234a33c538a4"),
                ("chat_template.jinja", 4168, "a55ee1b1660128b7098723e0abcd92caa0788061051c62d51cbe87d9cf1974d8"),
                ("LICENSE", 12033, "f715982df6ce767ae64864d74b95644e5d658aab54717dbceeb252eb3cbcb421"),
                ("NOTICE", 470, "4feae786f1766dc58e807bcae1e7bdd06bf3610a03a23d0621b6c6c4d05f2980"),
            ],
            secondsPerDictation: 0.4, memoryGB: 0.7, usesWordList: false),
    ]

    public static func model(_ id: CleanupModelID) -> CleanupModel {
        all.first { $0.id == id }!
    }
}

extension CleanupModelID: DownloadableModelID {
    public var downloadBytes: Int64? { CleanupModel.model(self).totalBytes }
}
