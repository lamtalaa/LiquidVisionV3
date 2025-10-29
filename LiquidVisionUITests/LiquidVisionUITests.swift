//
//  LiquidVisionUITests.swift
//  LiquidVisionUITests
//
//  Created by Yassine Lamtalaa on 10/14/25.
//
import XCTest

final class LiquidVisionUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        throw XCTSkip("UI tests are disabled while core functionality is under active development.")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        throw XCTSkip("UI tests are currently skipped.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        throw XCTSkip("UI tests are currently skipped.")
    }
}
