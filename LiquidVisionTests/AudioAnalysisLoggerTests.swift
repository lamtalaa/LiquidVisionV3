//
//  AudioAnalysisLoggerTests.swift
//  LiquidVisionTests
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import XCTest
@testable import LiquidVision

final class AudioAnalysisLoggerTests: XCTestCase {
    private let fileManager = FileManager.default
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory, fileManager.fileExists(atPath: temporaryDirectory.path) {
            try? fileManager.removeItem(at: temporaryDirectory)
        }

        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let logURL = documents?.appendingPathComponent("analysis_log.json")
        if let logURL, fileManager.fileExists(atPath: logURL.path) {
            try? fileManager.removeItem(at: logURL)
        }

        temporaryDirectory = nil
        try super.tearDownWithError()
    }

    func testLogWritesEntriesToOverrideDirectory() async throws {
        let expectedURL = temporaryDirectory.appendingPathComponent("analysis_log.json")

        let logger = AudioAnalysisLogger(
            fileManager: fileManager,
            fileName: "analysis_log.json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            environment: ["AUDIO_LOG_DIRECTORY": temporaryDirectory.path]
        )

        let firstEntry = AudioAnalysisLogEntry(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            timestamp: Date(timeIntervalSince1970: 0),
            source: .file,
            transcription: "hello world",
            classifications: [AudioClassificationResult(identifier: "speech", confidence: 0.9)]
        )

        let secondEntry = AudioAnalysisLogEntry(
            id: UUID(uuidString: "FFFFFFFF-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            timestamp: Date(timeIntervalSince1970: 10),
            source: .live,
            transcription: "typing",
            classifications: [AudioClassificationResult(identifier: "keyboard", confidence: 0.8)]
        )

        try await logger.log(entry: firstEntry)
        try await logger.log(entry: secondEntry)

        let data = try Data(contentsOf: expectedURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        let entries = try decoder.decode([AudioAnalysisLogEntry].self, from: data)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.first, firstEntry)
        XCTAssertEqual(entries.last, secondEntry)
    }

    func testLoggerFallsBackToDocumentsWhenOverrideFails() async throws {
        let invalidPath = "/System/Library/Private-Invalid-Path"
        let logger = AudioAnalysisLogger(
            fileManager: fileManager,
            fileName: "analysis_log.json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            environment: ["AUDIO_LOG_DIRECTORY": invalidPath]
        )

        let entry = AudioAnalysisLogEntry(
            id: UUID(),
            timestamp: Date(),
            source: .file,
            transcription: "test",
            classifications: []
        )

        try await logger.log(entry: entry)

        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let targetURL = documents.appendingPathComponent("analysis_log.json")
        XCTAssertTrue(fileManager.fileExists(atPath: targetURL.path))

        let data = try Data(contentsOf: targetURL)
        let decoded = try JSONDecoder().decode([AudioAnalysisLogEntry].self, from: data)
        XCTAssertEqual(decoded.first?.id, entry.id)
    }

    func testLoggerUsesProjectDirectoryWhenProvided() async throws {
        let expectedURL = temporaryDirectory.appendingPathComponent("analysis_log.json")

        let logger = AudioAnalysisLogger(
            fileManager: fileManager,
            fileName: "analysis_log.json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            environment: ["PROJECT_DIR": temporaryDirectory.path]
        )

        let entry = AudioAnalysisLogEntry(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            timestamp: Date(timeIntervalSince1970: 20),
            source: .live,
            transcription: "project dir",
            classifications: []
        )

        try await logger.log(entry: entry)

        let data = try Data(contentsOf: expectedURL)
        let decoded = try JSONDecoder().decode([AudioAnalysisLogEntry].self, from: data)
        XCTAssertEqual(decoded.first?.id, entry.id)
    }
}
