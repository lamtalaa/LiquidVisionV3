//
//  AudioFileAnalyzerTests.swift
//  LiquidVisionTests
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import AVFoundation
import SoundAnalysis
import Speech
import XCTest
@testable import LiquidVision

@MainActor
final class AudioFileAnalyzerTests: XCTestCase {
    private let fileManager = FileManager.default

    func testAnalyzeFileCombinesTranscriptionAndClassifications() async throws {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        fileManager.createFile(atPath: tempURL.path, contents: Data(), attributes: nil)

        let speechService = StubSpeechService(transcription: "hello world")
        let soundService = StubSoundService(results: [AudioClassificationResult(identifier: "speech", confidence: 0.87)])

        let analyzer = AudioFileAnalyzer(
            speechService: speechService,
            classificationService: soundService
        )

        let result = try await analyzer.analyzeFile(at: tempURL)
        XCTAssertEqual(result.transcription, "hello world")
        XCTAssertEqual(result.classifications.first?.identifier, "speech")
        XCTAssertEqual(result.classifications.first?.confidence, 0.87)
    }

    func testAnalyzeFileThrowsWhenFileIsUnreadable() async {
        let invalidURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let analyzer = AudioFileAnalyzer(
            speechService: StubSpeechService(transcription: "ignored"),
            classificationService: StubSoundService(results: [])
        )

        do {
            _ = try await analyzer.analyzeFile(at: invalidURL)
            XCTFail("Expected to throw for unreadable file")
        } catch let error as AudioFileAnalysisError {
            XCTAssertEqual(error, .invalidFile)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class StubSoundService: SoundClassificationServicing {
    let results: [AudioClassificationResult]

    init(results: [AudioClassificationResult]) {
        self.results = results
    }

    func classifyFile(at url: URL) async throws -> [AudioClassificationResult] {
        results
    }

    func makeStreamAnalyzer(observing observer: SNResultsObserving, format: AVAudioFormat) throws -> SNAudioStreamAnalyzer {
        fatalError("Not implemented in tests")
    }
}

private final class StubSpeechService: SpeechRecognitionServicing {
    let transcription: String

    init(transcription: String) {
        self.transcription = transcription
    }

    func ensureSpeechAuthorization() async throws { }
    func ensurePermissions() async throws { }

    func transcribeFile(at url: URL) async throws -> String {
        transcription
    }

    func makeRecognizer() throws -> SFSpeechRecognizer {
        throw SpeechRecognitionError.recognizerUnavailable
    }
}
