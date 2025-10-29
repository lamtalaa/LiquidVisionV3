//
//  LiveAudioAnalyzer.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import AVFoundation
import SoundAnalysis
import Speech

struct LiveAudioHandlers {
    let onTranscription: @Sendable (String) -> Void
    let onClassifications: @Sendable ([AudioClassificationResult]) -> Void
    let onError: @Sendable (Error) -> Void
    let onCompletion: @Sendable (String, [AudioClassificationResult]) -> Void
}

protocol LiveAudioSessionControlling {
    func stop()
    func cancel()
}

protocol LiveAudioAnalyzing {
    func start(handlers: LiveAudioHandlers) throws -> LiveAudioSessionControlling
}

final class LiveAudioAnalyzer: NSObject, LiveAudioAnalyzing {
    private let speechService: SpeechRecognitionServicing
    private let classificationService: SoundClassificationServicing
    private let audioSession: AVAudioSession
    private let analysisQueue = DispatchQueue(label: "com.liquidvision.audio-analysis")

    init(
        speechService: SpeechRecognitionServicing = SpeechRecognitionService(),
        classificationService: SoundClassificationServicing = SoundClassificationService(),
        audioSession: AVAudioSession = .sharedInstance()
    ) {
        self.speechService = speechService
        self.classificationService = classificationService
        self.audioSession = audioSession
    }

    func start(handlers: LiveAudioHandlers) throws -> LiveAudioSessionControlling {
        let recognizer = try speechService.makeRecognizer()
        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        var latestClassifications: [AudioClassificationResult] = []
        var latestTranscript = ""

        let observer = LiveStreamClassificationObserver(
            resultHandler: { results in
                latestClassifications = results
                DispatchQueue.main.async {
                    handlers.onClassifications(results)
                }
            },
            errorHandler: { error in
                DispatchQueue.main.async {
                    handlers.onError(error)
                }
            }
        )

        try configureAudioSession()

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let streamAnalyzer = try classificationService.makeStreamAnalyzer(observing: observer, format: format)

        var framePosition: AVAudioFramePosition = 0

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [analysisQueue = analysisQueue] buffer, time in
            let currentPosition: AVAudioFramePosition
            if time.sampleTime != -1 {
                currentPosition = time.sampleTime
                framePosition = currentPosition
            } else {
                framePosition += AVAudioFramePosition(buffer.frameLength)
                currentPosition = framePosition
            }

            analysisQueue.async {
                streamAnalyzer.analyze(buffer, atAudioFramePosition: currentPosition)
            }

            request.append(buffer)
        }

        engine.prepare()
        try engine.start()

        let task = recognizer.recognitionTask(with: request) { result, error in
            if let error {
                handlers.onError(error)
                return
            }

            guard let result else { return }
            let transcription = result.bestTranscription.formattedString
            latestTranscript = transcription
            DispatchQueue.main.async {
                handlers.onTranscription(transcription)
            }

            _ = result.isFinal
        }

        return LiveAudioSession(
            engine: engine,
            recognitionTask: task,
            recognitionRequest: request,
            streamAnalyzer: streamAnalyzer,
            inputNode: inputNode,
            latestState: { (latestTranscript, latestClassifications) },
            handlers: handlers,
            analysisQueue: analysisQueue,
            audioSession: audioSession,
            observer: observer
        )
    }

    private func configureAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

private final class LiveStreamClassificationObserver: NSObject, SNResultsObserving {
    private let resultHandler: @Sendable ([AudioClassificationResult]) -> Void
    private let errorHandler: @Sendable (Error) -> Void

    init(
        resultHandler: @escaping @Sendable ([AudioClassificationResult]) -> Void,
        errorHandler: @escaping @Sendable (Error) -> Void
    ) {
        self.resultHandler = resultHandler
        self.errorHandler = errorHandler
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        let items = classificationResult.classifications.prefix(3).map {
            AudioClassificationResult(identifier: $0.identifier, confidence: Double($0.confidence))
        }
        resultHandler(items)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        errorHandler(error)
    }
}

private final class LiveAudioSession: LiveAudioSessionControlling {
    private let engine: AVAudioEngine
    private let recognitionTask: SFSpeechRecognitionTask
    private let recognitionRequest: SFSpeechAudioBufferRecognitionRequest
    private let streamAnalyzer: SNAudioStreamAnalyzer
    private weak var inputNode: AVAudioInputNode?
    private let latestState: () -> (String, [AudioClassificationResult])
    private let handlers: LiveAudioHandlers
    private let analysisQueue: DispatchQueue
    private let audioSession: AVAudioSession
    private let observer: LiveStreamClassificationObserver

    init(
        engine: AVAudioEngine,
        recognitionTask: SFSpeechRecognitionTask,
        recognitionRequest: SFSpeechAudioBufferRecognitionRequest,
        streamAnalyzer: SNAudioStreamAnalyzer,
        inputNode: AVAudioInputNode,
        latestState: @escaping () -> (String, [AudioClassificationResult]),
        handlers: LiveAudioHandlers,
        analysisQueue: DispatchQueue,
        audioSession: AVAudioSession,
        observer: LiveStreamClassificationObserver
    ) {
        self.engine = engine
        self.recognitionTask = recognitionTask
        self.recognitionRequest = recognitionRequest
        self.streamAnalyzer = streamAnalyzer
        self.inputNode = inputNode
        self.latestState = latestState
        self.handlers = handlers
        self.analysisQueue = analysisQueue
        self.audioSession = audioSession
        self.observer = observer
    }

    func stop() {
        recognitionTask.cancel()
        recognitionRequest.endAudio()
        inputNode?.removeTap(onBus: 0)
        engine.stop()
        analysisQueue.async { [streamAnalyzer] in
            streamAnalyzer.completeAnalysis()
        }
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        let state = latestState()
        DispatchQueue.main.async {
            self.handlers.onCompletion(state.0, state.1)
        }
    }

    func cancel() {
        recognitionTask.cancel()
        recognitionRequest.endAudio()
        inputNode?.removeTap(onBus: 0)
        engine.stop()
        analysisQueue.async { [streamAnalyzer] in
            streamAnalyzer.completeAnalysis()
        }
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
}
