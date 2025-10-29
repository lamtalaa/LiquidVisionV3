//
//  TestHelpers.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import Foundation
import XCTest

@MainActor
extension XCTestCase {
    func waitForCondition(
        timeout: TimeInterval = 1.0,
        pollInterval: UInt64 = 50_000_000,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() { return }
            try await Task.sleep(nanoseconds: pollInterval)
        }
        XCTFail("Timed out waiting for condition", file: #file, line: #line)
    }
}
