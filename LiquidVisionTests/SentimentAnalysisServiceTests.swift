//
//  SentimentAnalysisServiceTests.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import XCTest
@testable import LiquidVision

final class SentimentAnalysisServiceTests: XCTestCase {
    func testAnalyzePositiveTextReturnsPositiveSentiment() async throws {
        let service = SentimentAnalysisService()
        let result = try await service.analyze(text: "I absolutely love this product, it is fantastic!")
        XCTAssertEqual(result.sentiment, .positive)
        XCTAssertGreaterThan(result.score, 0)
    }

    func testAnalyzeNegativeTextReturnsNegativeSentiment() async throws {
        let service = SentimentAnalysisService()
        let result = try await service.analyze(text: "This is the worst experience I have ever had.")
        XCTAssertEqual(result.sentiment, .negative)
        XCTAssertLessThan(result.score, 0)
    }

    func testAnalyzeEmptyTextThrows() async {
        let service = SentimentAnalysisService()
        do {
            _ = try await service.analyze(text: "   ")
            XCTFail("Expected empty text to throw")
        } catch let error as SentimentAnalysisError {
            switch error {
            case .emptyText:
                break
            default:
                XCTFail("Unexpected SentimentAnalysisError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
