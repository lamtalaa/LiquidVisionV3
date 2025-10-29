//
//  AudioFileAnalyzer.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import Foundation

protocol AudioFileAnalyzing {
    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult
}

enum AudioFileAnalysisError: LocalizedError {
    case invalidFile

    var errorDescription: String? {
        "The selected audio file could not be analyzed."
    }
}

final class AudioFileAnalyzer: AudioFileAnalyzing {
    private let speechService: SpeechRecognitionServicing
    private let classificationService: SoundClassificationServicing

    init(
        speechService: SpeechRecognitionServicing = SpeechRecognitionService(),
        classificationService: SoundClassificationServicing = SoundClassificationService()
    ) {
        self.speechService = speechService
        self.classificationService = classificationService
    }

    func analyzeFile(at url: URL) async throws -> AudioFileAnalysisResult {
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw AudioFileAnalysisError.invalidFile
        }

        async let transcriptionTask = speechService.transcribeFile(at: url)
        async let classificationTask = classificationService.classifyFile(at: url)

        do {
            let (transcription, classifications) = try await (transcriptionTask, classificationTask)
            return AudioFileAnalysisResult(transcription: transcription, classifications: classifications)
        } catch {
            throw error
        }
    }
}
