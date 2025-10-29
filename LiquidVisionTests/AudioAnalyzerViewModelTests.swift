//
//  AudioAnalyzerViewModelTests.swift
//  LiquidVisionTests
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import Speech
import Speech
import XCTest
@testable import LiquidVision

@MainActor
final class AudioAnalyzerViewModelTests: XCTestCase {
    func testAnalyzeFileSuccessUpdatesStateAndLogs() async throws {
        let speechService = MockSpeechService()
        let expectedResult = AudioFileAnalysisResult(
            transcription: "hello world",
            classifications: [AudioClassificationResult(identifier: "speech", confidence: 0.88)]
        )
        let fileAnalyzer = MockFileAnalyzer(result: .success(expectedResult))
        let logger = MockAudioLogger()
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: fileAnalyzer,
            liveAnalyzer: MockLiveAudioAnalyzer(),
            logger: logger,
            dateProvider: { Date(timeIntervalSince1970: 0) }
        )

        await viewModel.analyzeFile(at: URL(fileURLWithPath: "/tmp/mock.m4a"))

        try await waitForCondition {
            viewModel.state.isAnalyzingFile == false &&
            viewModel.state.transcription == expectedResult.transcription
        }

        XCTAssertTrue(speechService.didRequestSpeechAuthorization)
        XCTAssertEqual(viewModel.state.classifications, expectedResult.classifications)
        XCTAssertEqual(logger.entries.count, 1)
        XCTAssertEqual(logger.entries.first?.source, .file)
        XCTAssertEqual(logger.entries.first?.transcription, expectedResult.transcription)
    }

    func testAnalyzeFileFailureShowsError() async throws {
        let speechService = MockSpeechService()
        let fileAnalyzer = MockFileAnalyzer(result: .failure(AudioFileAnalysisError.invalidFile))
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: fileAnalyzer,
            liveAnalyzer: MockLiveAudioAnalyzer(),
            logger: MockAudioLogger()
        )

        await viewModel.analyzeFile(at: URL(fileURLWithPath: "/tmp/mock.m4a"))

        try await waitForCondition {
            viewModel.state.isAnalyzingFile == false && viewModel.state.errorMessage != nil
        }

        XCTAssertEqual(viewModel.state.errorMessage, AudioFileAnalysisError.invalidFile.errorDescription)
    }

    func testToggleLiveAnalysisStartAndStopUpdatesState() async throws {
        let speechService = MockSpeechService()
        let liveAnalyzer = MockLiveAudioAnalyzer()
        let logger = MockAudioLogger()
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: MockFileAnalyzer(result: .failure(AudioFileAnalysisError.invalidFile)),
            liveAnalyzer: liveAnalyzer,
            logger: logger,
            dateProvider: { Date(timeIntervalSince1970: 0) }
        )

        viewModel.toggleLiveAnalysis()
        try await waitForCondition { viewModel.state.isRecordingLive }

        liveAnalyzer.sendTranscription("partial transcript")
        liveAnalyzer.sendClassifications([AudioClassificationResult(identifier: "voice", confidence: 0.7)])

        try await waitForCondition {
            viewModel.state.transcription == "partial transcript" &&
            viewModel.state.classifications.isEmpty == false
        }

        viewModel.toggleLiveAnalysis()
        try await waitForCondition { viewModel.state.isRecordingLive == false }

        XCTAssertEqual(logger.entries.count, 1)
        XCTAssertEqual(logger.entries.first?.source, .live)
        XCTAssertEqual(logger.entries.first?.classifications.first?.identifier, "voice")
    }

    func testLiveAnalysisErrorCancelsSession() async throws {
        let speechService = MockSpeechService()
        let liveAnalyzer = MockLiveAudioAnalyzer()
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: MockFileAnalyzer(result: .failure(AudioFileAnalysisError.invalidFile)),
            liveAnalyzer: liveAnalyzer,
            logger: MockAudioLogger()
        )

        viewModel.toggleLiveAnalysis()
        try await waitForCondition { liveAnalyzer.activeHandlers != nil }

        liveAnalyzer.sendError(MockError.sample)

        try await waitForCondition { viewModel.state.errorMessage == MockError.sample.localizedDescription }
        XCTAssertFalse(viewModel.state.isRecordingLive)
        XCTAssertEqual(liveAnalyzer.didCancelCount, 1)
    }

    func testLiveCompletionWithNoResultsSkipsLogging() async throws {
        let speechService = MockSpeechService()
        let liveAnalyzer = MockLiveAudioAnalyzer()
        let logger = MockAudioLogger()
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: MockFileAnalyzer(result: .failure(AudioFileAnalysisError.invalidFile)),
            liveAnalyzer: liveAnalyzer,
            logger: logger,
            dateProvider: { Date(timeIntervalSince1970: 0) }
        )

        viewModel.toggleLiveAnalysis()
        try await waitForCondition { liveAnalyzer.activeHandlers != nil }

        liveAnalyzer.sendCompletion("", [])

        try await waitForCondition {
            viewModel.state.isRecordingLive == false &&
            viewModel.state.infoMessage == "No sounds detected."
        }

        XCTAssertEqual(logger.entries.count, 0)
        XCTAssertEqual(viewModel.state.transcription, "")
        XCTAssertTrue(viewModel.state.classifications.isEmpty)
    }

    func testAnalyzeFilePermissionDeniedSetsError() async throws {
        let speechService = PermissionFailingSpeechService(error: SpeechRecognitionError.permissionDenied)
        let fileAnalyzer = MockFileAnalyzer(result: .success(AudioFileAnalysisResult(transcription: "", classifications: [])))
        let logger = MockAudioLogger()
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: fileAnalyzer,
            liveAnalyzer: MockLiveAudioAnalyzer(),
            logger: logger
        )

        await viewModel.analyzeFile(at: URL(fileURLWithPath: "/tmp/mock.m4a"))

        XCTAssertEqual(viewModel.state.errorMessage, SpeechRecognitionError.permissionDenied.errorDescription)
        XCTAssertEqual(logger.entries.count, 0)
    }

    func testToggleLiveAnalysisPermissionDeniedShowsError() async throws {
        let speechService = PermissionFailingSpeechService(error: SpeechRecognitionError.permissionDenied, failOnPermissions: true)
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: MockFileAnalyzer(result: .failure(AudioFileAnalysisError.invalidFile)),
            liveAnalyzer: MockLiveAudioAnalyzer(),
            logger: MockAudioLogger()
        )

        viewModel.toggleLiveAnalysis()

        try await waitForCondition { viewModel.state.errorMessage == SpeechRecognitionError.permissionDenied.errorDescription }
        XCTAssertFalse(viewModel.state.isRecordingLive)
    }

    func testLiveCompletionLogsWhenResultsPresent() async throws {
        let speechService = MockSpeechService()
        let liveAnalyzer = MockLiveAudioAnalyzer()
        let logger = MockAudioLogger()
        let viewModel = AudioAnalyzerViewModel(
            speechService: speechService,
            fileAnalyzer: MockFileAnalyzer(result: .failure(AudioFileAnalysisError.invalidFile)),
            liveAnalyzer: liveAnalyzer,
            logger: logger,
            dateProvider: { Date(timeIntervalSince1970: 42) }
        )

        viewModel.toggleLiveAnalysis()
        try await waitForCondition { liveAnalyzer.activeHandlers != nil }

        let classifications = [AudioClassificationResult(identifier: "speech", confidence: 0.9)]
        liveAnalyzer.sendCompletion("hello", classifications)

        try await waitForCondition { logger.entries.count == 1 }
        XCTAssertEqual(logger.entries.first?.transcription, "hello")
        XCTAssertEqual(logger.entries.first?.classifications.first?.identifier, "speech")
    }
}

@MainActor
private final class MockSpeechService: SpeechRecognitionServicing {
    var didRequestSpeechAuthorization = false
    var didRequestPermissions = false

    func ensureSpeechAuthorization() async throws {
        didRequestSpeechAuthorization = true
    }

    func ensurePermissions() async throws {
        didRequestPermissions = true
    }

    func transcribeFile(at url: URL) async throws -> String {
        "transcribed text"
    }

    func makeRecognizer() throws -> SFSpeechRecognizer {
        throw SpeechRecognitionError.recognizerUnavailable
    }
}

private final class MockFileAnalyzer: AudioFileAnalyzing {
    let result: Result<AudioFileAnalysisResult, Error>

    init(result: Result<AudioFileAnalysisResult, Error>) {
        self.result = result
    }

    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult {
        try result.get()
    }
}

@MainActor
private final class MockAudioLogger: AudioAnalysisLogging {
    private(set) var entries: [AudioAnalysisLogEntry] = []

    func log(entry: AudioAnalysisLogEntry) async throws {
        entries.append(entry)
    }
}

private final class MockLiveAudioAnalyzer: LiveAudioAnalyzing {
    private(set) var activeHandlers: LiveAudioHandlers?
    private(set) var session = MockLiveSession()
    private(set) var didCancelCount = 0

    func start(handlers: LiveAudioHandlers) throws -> LiveAudioSessionControlling {
        activeHandlers = handlers
        session.onStop = {
            handlers.onCompletion("partial transcript", [AudioClassificationResult(identifier: "voice", confidence: 0.7)])
        }
        session.onCancel = { [weak self] in
            self?.didCancelCount += 1
        }
        return session
    }

    func sendTranscription(_ text: String) {
        activeHandlers?.onTranscription(text)
    }

    func sendClassifications(_ results: [AudioClassificationResult]) {
        activeHandlers?.onClassifications(results)
    }

    func sendError(_ error: Error) {
        activeHandlers?.onError(error)
    }

    func sendCompletion(_ transcript: String, _ results: [AudioClassificationResult]) {
        activeHandlers?.onCompletion(transcript, results)
    }
}

private final class MockLiveSession: LiveAudioSessionControlling {
    var onStop: (() -> Void)?
    var onCancel: (() -> Void)?

    func stop() {
        onStop?()
    }

    func cancel() {
        onCancel?()
    }
}

private enum MockError: Error, LocalizedError {
    case sample

    var errorDescription: String? { "Sample error" }
}

private final class PermissionFailingSpeechService: SpeechRecognitionServicing {
    private let error: Error
    private let failOnPermissions: Bool

    init(error: Error, failOnPermissions: Bool = false) {
        self.error = error
        self.failOnPermissions = failOnPermissions
    }

    func ensureSpeechAuthorization() async throws {
        if failOnPermissions == false {
            throw error
        }
    }

    func ensurePermissions() async throws {
        throw error
    }

    func transcribeFile(at url: URL) async throws -> String {
        throw error
    }

    func makeRecognizer() throws -> SFSpeechRecognizer {
        throw SpeechRecognitionError.recognizerUnavailable
    }
}
