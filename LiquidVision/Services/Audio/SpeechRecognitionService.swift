//
//  SpeechRecognitionService.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import AVFoundation
import Speech

protocol SpeechRecognitionServicing {
    func ensureSpeechAuthorization() async throws
    func ensurePermissions() async throws
    func transcribeFile(at url: URL) async throws -> String
    func makeRecognizer() throws -> SFSpeechRecognizer
}

enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case recognizerUnavailable
    case onDeviceNotSupported
    case transcriptionFailed
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission is required."
        case .recognizerUnavailable:
            return "Speech recognizer is unavailable."
        case .onDeviceNotSupported:
            return "On-device speech recognition is not supported."
        case .transcriptionFailed:
            return "Unable to transcribe audio."
        case .emptyResult:
            return "No transcription was produced."
        }
    }
}

final class SpeechRecognitionService: SpeechRecognitionServicing {
    private let audioSession: AVAudioSession

    init(audioSession: AVAudioSession = .sharedInstance()) {
        self.audioSession = audioSession
    }

    func ensureSpeechAuthorization() async throws {
        let status = await requestSpeechAuthorization()
        guard status == .authorized else { throw SpeechRecognitionError.permissionDenied }
    }

    func ensurePermissions() async throws {
        try await ensureSpeechAuthorization()
        let microphoneGranted = await requestMicrophonePermission()
        guard microphoneGranted else { throw SpeechRecognitionError.permissionDenied }
    }

    func transcribeFile(at url: URL) async throws -> String {
        let recognizer = try makeRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { continuation in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else { return }

                if result.isFinal {
                    let transcription = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if transcription.isEmpty {
                        continuation.resume(throwing: SpeechRecognitionError.emptyResult)
                    } else {
                        continuation.resume(returning: transcription)
                    }
                }
            }

            if task == nil {
                continuation.resume(throwing: SpeechRecognitionError.transcriptionFailed)
            }
        }
    }

    func makeRecognizer() throws -> SFSpeechRecognizer {
        guard let recognizer = SFSpeechRecognizer() else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        if recognizer.supportsOnDeviceRecognition == false {
            throw SpeechRecognitionError.onDeviceNotSupported
        }

        return recognizer
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
