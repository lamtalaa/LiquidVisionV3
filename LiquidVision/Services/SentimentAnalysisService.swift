//
//  SentimentAnalysisService.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import Foundation
import NaturalLanguage

struct SentimentAnalysisResult: Equatable {
    let score: Double
    let sentiment: SentimentPolarity
}

enum SentimentPolarity: String, Equatable {
    case negative
    case neutral
    case positive

    init(score: Double) {
        switch score {
        case ..<0:
            self = .negative
        case 0:
            self = .neutral
        default:
            self = .positive
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

enum SentimentAnalysisError: LocalizedError {
    case emptyText
    case noScore
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "Please enter some text to analyze."
        case .noScore:
            return "Unable to evaluate sentiment for the provided text."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

protocol SentimentAnalysisServicing {
    func analyze(text: String) async throws -> SentimentAnalysisResult
}

final class SentimentAnalysisService: SentimentAnalysisServicing {
    func analyze(text: String) async throws -> SentimentAnalysisResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            throw SentimentAnalysisError.emptyText
        }

        return try await Task.detached(priority: .userInitiated) {
            try Self.evaluateSentiment(for: trimmed)
        }.value
    }

    private static func evaluateSentiment(for text: String) throws -> SentimentAnalysisResult {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let fullRange = text.startIndex..<text.endIndex
        if let language = NLLanguageRecognizer.dominantLanguage(for: text) {
            tagger.setLanguage(language, range: fullRange)
        }

        let (paragraphTag, _) = tagger.tag(at: fullRange.lowerBound, unit: .paragraph, scheme: .sentimentScore)
        if let paragraphScore = score(from: paragraphTag) {
            return SentimentAnalysisResult(score: paragraphScore, sentiment: SentimentPolarity(score: paragraphScore))
        }

        var runningTotal: Double = 0
        var sentenceCount: Double = 0

        tagger.enumerateTags(in: fullRange, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let value = score(from: tag) {
                runningTotal += value
                sentenceCount += 1
            }
            return true
        }

        guard sentenceCount > 0 else {
            throw SentimentAnalysisError.noScore
        }

        let average = runningTotal / sentenceCount
        return SentimentAnalysisResult(score: average, sentiment: SentimentPolarity(score: average))
    }

    private static func score(from tag: NLTag?) -> Double? {
        guard let raw = tag?.rawValue else { return nil }
        return Double(raw)
    }
}
