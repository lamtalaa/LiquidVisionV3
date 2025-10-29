//
//  AudioAnalysisLogger.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import Foundation

protocol AudioAnalysisLogging {
    func log(entry: AudioAnalysisLogEntry) async throws
}

actor AudioAnalysisLogger: AudioAnalysisLogging {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        fileManager: FileManager = .default,
        fileName: String = "analysis_log.json",
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.fileManager = fileManager
        self.fileURL = AudioAnalysisLogger.makeFileURL(
            fileManager: fileManager,
            fileName: fileName,
            environment: environment
        )
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func log(entry: AudioAnalysisLogEntry) async throws {
        var entries = try await loadExistingEntries()
        entries.append(entry)
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: [.atomic])
    }

    private func loadExistingEntries() async throws -> [AudioAnalysisLogEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([AudioAnalysisLogEntry].self, from: data)
    }

    private static func makeFileURL(
        fileManager: FileManager,
        fileName: String,
        environment: [String: String]
    ) -> URL {
        let preferredDirectories = resolvePreferredDirectories(environment: environment)

        for directory in preferredDirectories {
            let fileURL = directory.appendingPathComponent(fileName, isDirectory: false)
            if ensureDirectoryExists(at: directory, fileManager: fileManager) {
                return fileURL
            }
        }

        let fallback = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        _ = ensureDirectoryExists(at: fallback, fileManager: fileManager)
        return fallback.appendingPathComponent(fileName, isDirectory: false)
    }

    private static func resolvePreferredDirectories(environment: [String: String]) -> [URL] {
        var directories: [URL] = []

        if let overridePath = environment["AUDIO_LOG_DIRECTORY"], overridePath.isEmpty == false {
        directories.append(URL(fileURLWithPath: overridePath, isDirectory: true))
        }

        if let projectDir = environment["PROJECT_DIR"], projectDir.isEmpty == false {
            directories.append(URL(fileURLWithPath: projectDir, isDirectory: true)
                .appendingPathComponent("LiquidVision", isDirectory: true))
    }

        return directories
    }

    private static func ensureDirectoryExists(at url: URL, fileManager: FileManager) -> Bool {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableURL = url
            try? mutableURL.setResourceValues(resourceValues)
            return true
        } catch {
            return false
        }
    }
}
