//
//  ImageClassificationService.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import CoreImage
import UIKit

struct ClassificationResult: Equatable {
    let identifier: String
    let confidence: Double
}

enum ImageClassificationError: LocalizedError {
    case invalidImage
    case noResult
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to create CIImage."
        case .noResult:
            return "No prediction available."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

protocol ImageClassificationServicing {
    func classify(image: UIImage) async throws -> ClassificationResult
}
