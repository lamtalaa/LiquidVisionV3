//
//  AudioAnalyzerViewModel.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import Foundation
import SwiftUI

struct AudioAnalyzerViewState {
    enum ActiveSource: Equatable {
        case none
        case file(name: String)
        case live
    }

    var activeSource: ActiveSource = .none
    var transcription: String = ""
    var classifications: [AudioClassificationResult] = []
    var isAnalyzingFile = false
    var isRecordingLive = false
    var errorMessage: String?
    var infoMessage: String?
}

final class AudioAnalyzerViewModel: ObservableObject {
    @Published private(set) var state = AudioAnalyzerViewState()

    private let speechService: SpeechRecognitionServicing
    private let fileAnalyzer: AudioFileAnalyzing
    private let liveAnalyzer: LiveAudioAnalyzing
    private let logger: AudioAnalysisLogging
    private let dateProvider: () -> Date

    private var liveSession: LiveAudioSessionControlling?

    init(
        speechService: SpeechRecognitionServicing = SpeechRecognitionService(),
        fileAnalyzer: AudioFileAnalyzing = AudioFileAnalyzer(),
        liveAnalyzer: LiveAudioAnalyzing = LiveAudioAnalyzer(),
        logger: AudioAnalysisLogging = AudioAnalysisLogger(),
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.speechService = speechService
        self.fileAnalyzer = fileAnalyzer
        self.liveAnalyzer = liveAnalyzer
        self.logger = logger
        self.dateProvider = dateProvider
    }

    @MainActor
    func analyzeFile(at url: URL) async {
        setStateForFileStart(fileName: url.lastPathComponent)
        do {
            try await speechService.ensureSpeechAuthorization()
            let result = try await fileAnalyzer.analyzeFile(at: url)
            setStateForFileSuccess(result: result)
            try await logger.log(entry: makeLogEntry(
                source: .file,
                transcription: result.transcription,
                classifications: result.classifications
            ))
        } catch {
            setStateForFileFailure(error: error)
        }
    }

    @MainActor
    func toggleLiveAnalysis() {
        if let session = liveSession {
            session.stop()
            liveSession = nil
            return
        }

        Task { @MainActor in
            do {
                try await speechService.ensurePermissions()
                setStateForLiveStart()
                let handlers = LiveAudioHandlers(
                    onTranscription: { [weak self] text in
                        Task { [weak self] in
                            guard let self else { return }
                            await MainActor.run {
                                self.updateTranscription(text)
                            }
                        }
                    },
                    onClassifications: { [weak self] results in
                        Task { [weak self] in
                            guard let self else { return }
                            await MainActor.run {
                                self.updateClassifications(results)
                            }
                        }
                    },
                    onError: { [weak self] error in
                        Task { [weak self] in
                            guard let self else { return }
                            await MainActor.run {
                                self.handleLiveError(error)
                            }
                        }
                    },
                    onCompletion: { [weak self] transcript, results in
                        Task { [weak self] in
                            guard let self else { return }
                            await self.handleLiveCompletion(transcript: transcript, results: results)
                        }
                    }
                )

                let session = try liveAnalyzer.start(handlers: handlers)
                liveSession = session
            } catch {
                handleLiveError(error)
            }
        }
    }

    @MainActor
    func binding<Value>(_ keyPath: WritableKeyPath<AudioAnalyzerViewState, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in self.state[keyPath: keyPath] = newValue }
        )
    }

    @MainActor
    private func setStateForFileStart(fileName: String) {
        state.activeSource = .file(name: fileName)
        state.transcription = ""
        state.classifications = []
        state.isAnalyzingFile = true
        state.errorMessage = nil
        state.infoMessage = nil
    }

    @MainActor
    private func setStateForFileSuccess(result: AudioFileAnalysisResult) {
        state.transcription = result.transcription
        state.classifications = result.classifications
        state.isAnalyzingFile = false
        state.errorMessage = nil
        state.infoMessage = "File analysis completed."
    }

    @MainActor
    private func setStateForFileFailure(error: Error) {
        state.isAnalyzingFile = false
        state.classifications = []
        state.errorMessage = userFriendlyMessage(for: error)
        state.infoMessage = nil
    }

    @MainActor
    private func setStateForLiveStart() {
        state.activeSource = .live
        state.transcription = ""
        state.classifications = []
        state.isRecordingLive = true
        state.errorMessage = nil
        state.infoMessage = "Listening…"
    }

    @MainActor
    private func updateTranscription(_ text: String) {
        state.transcription = text
    }

    @MainActor
    private func updateClassifications(_ results: [AudioClassificationResult]) {
        state.classifications = results
    }

    @MainActor
    private func handleLiveError(_ error: Error) {
        state.errorMessage = userFriendlyMessage(for: error)
        state.infoMessage = nil
        state.isRecordingLive = false
        liveSession?.cancel()
        liveSession = nil
    }

    @MainActor
    private func handleLiveCompletion(transcript: String, results: [AudioClassificationResult]) async {
        state.isRecordingLive = false
        state.infoMessage = results.isEmpty ? "No sounds detected." : "Live analysis stopped."
        state.errorMessage = nil
        state.transcription = transcript
        state.classifications = results
        liveSession = nil

        if transcript.isEmpty && results.isEmpty {
            return
        }

        try? await logger.log(entry: makeLogEntry(
            source: .live,
            transcription: transcript,
            classifications: results
        ))
    }

    private func userFriendlyMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    private func makeLogEntry(
        source: AudioAnalysisSource,
        transcription: String,
        classifications: [AudioClassificationResult]
    ) -> AudioAnalysisLogEntry {
        AudioAnalysisLogEntry(
            id: UUID(),
            timestamp: dateProvider(),
            source: source,
            transcription: transcription,
            classifications: classifications
        )
    }
}
