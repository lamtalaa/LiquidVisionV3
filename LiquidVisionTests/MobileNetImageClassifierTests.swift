//
//  MobileNetImageClassifierTests.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import UIKit
import XCTest
@testable import LiquidVision

final class MobileNetImageClassifierTests: XCTestCase {
    func testClassifyReturnsResultForSolidImage() async throws {
        let classifier = MobileNetImageClassifier()
        let image = TestImageFactory.makeSolidColorImage()

        do {
            let result = try await classifier.classify(image: image)
            XCTAssertFalse(result.identifier.isEmpty)
            XCTAssertGreaterThanOrEqual(result.confidence, 0)
            XCTAssertLessThanOrEqual(result.confidence, 1)
        } catch ImageClassificationError.underlying(let error as ImageClassificationServiceInitializationError) {
            throw XCTSkip("MobileNet model unavailable: \(error.localizedDescription)")
        }
    }

    func testClassifyThrowsForInvalidImage() async throws {
        let classifier = MobileNetImageClassifier()
        let invalidImage = UIImage()

        do {
            _ = try await classifier.classify(image: invalidImage)
            XCTFail("Expected to throw for invalid image")
        } catch ImageClassificationError.invalidImage {
            // expected
        } catch ImageClassificationError.underlying(let error as ImageClassificationServiceInitializationError) {
            throw XCTSkip("MobileNet model unavailable: \(error.localizedDescription)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
