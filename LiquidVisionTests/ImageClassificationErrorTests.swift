//
//  ImageClassificationErrorTests.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import XCTest
@testable import LiquidVision

final class ImageClassificationErrorTests: XCTestCase {
    func testLocalizedDescriptions() {
        XCTAssertEqual(ImageClassificationError.invalidImage.errorDescription, "Unable to create CIImage.")
        XCTAssertEqual(ImageClassificationError.noResult.errorDescription, "No prediction available.")

        let sampleError = NSError(domain: "test", code: -1)
        let wrapped = ImageClassificationError.underlying(sampleError)
        XCTAssertEqual(wrapped.errorDescription, sampleError.localizedDescription)
    }

    func testInitializationErrorDescription() {
        let error = ImageClassificationServiceInitializationError.failedToLoadModel
        XCTAssertEqual(error.errorDescription, "Unable to load Core ML model.")
    }
}
