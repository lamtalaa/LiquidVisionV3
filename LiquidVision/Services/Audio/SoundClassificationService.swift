//
//  SoundClassificationService.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import AVFoundation
import SoundAnalysis

protocol SoundClassificationServicing {
    func classifyFile(at url: URL) async throws -> [AudioClassificationResult]
    func makeStreamAnalyzer(observing observer: SNResultsObserving, format: AVAudioFormat) throws -> SNAudioStreamAnalyzer
}

enum SoundClassificationError: LocalizedError {
    case requestCreationFailed
    case analysisFailed
    case noResults
    case unsupported

    var errorDescription: String? {
        switch self {
        case .requestCreationFailed:
            return "Unable to start sound classification."
        case .analysisFailed:
            return "Sound analysis failed."
        case .noResults:
            return "No sound classification results were produced."
        case .unsupported:
            return "Sound classification is not available on this device."
        }
    }
}

final class SoundClassificationService: NSObject, SoundClassificationServicing {
    func classifyFile(at url: URL) async throws -> [AudioClassificationResult] {
        let analyzer = try SNAudioFileAnalyzer(url: url)
        let request = try makeRequest()
        let observer = AudioFileClassificationObserver()
        try analyzer.add(request, withObserver: observer)
        await analyzer.analyze()
        do {
            let results = try await observer.awaitClassifications()
            guard results.isEmpty == false else { throw SoundClassificationError.noResults }
            return results
        } catch let error as SoundClassificationError {
            throw error
        } catch {
            throw SoundClassificationError.analysisFailed
        }
    }

    func makeStreamAnalyzer(observing observer: SNResultsObserving, format: AVAudioFormat) throws -> SNAudioStreamAnalyzer {
        let request = try makeRequest()
        let analyzer = SNAudioStreamAnalyzer(format: format)
        try analyzer.add(request, withObserver: observer)
        return analyzer
    }

    private func makeRequest() throws -> SNClassifySoundRequest {
        do {
            return try SNClassifySoundRequest(classifierIdentifier: .version1)
        } catch {
            throw SoundClassificationError.requestCreationFailed
        }
    }
}

private final class AudioFileClassificationObserver: NSObject, SNResultsObserving {
    private var continuation: CheckedContinuation<[AudioClassificationResult], Error>?
    private var latest: [AudioClassificationResult] = []
    private var didFinish = false

    func awaitClassifications() async throws -> [AudioClassificationResult] {
        try await withCheckedThrowingContinuation { continuation in
            if didFinish {
                continuation.resume(returning: latest)
            } else {
                self.continuation = continuation
            }
        }
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        let items = classificationResult.classifications.prefix(3).map {
            AudioClassificationResult(identifier: $0.identifier, confidence: Double($0.confidence))
        }
        latest = items
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func requestDidComplete(_ request: SNRequest) {
        didFinish = true
        if let continuation {
            continuation.resume(returning: latest)
            self.continuation = nil
        }
    }
}
