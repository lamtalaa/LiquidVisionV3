//
//  MobileNetImageClassifier.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
@preconcurrency import CoreImage
import CoreML
import Foundation
import UIKit
@preconcurrency import Vision

actor MobileNetImageClassifier: ImageClassificationServicing {
    private lazy var visionModel: VNCoreMLModel? = {
        do {
            let configuration = MLModelConfiguration()
            let model = try MobileNetV2(configuration: configuration)
            return try VNCoreMLModel(for: model.model)
        } catch {
            return nil
        }
    }()

    func classify(image: UIImage) async throws -> ClassificationResult {
        guard let ciImage = CIImage(image: image) else {
            throw ImageClassificationError.invalidImage
        }

        guard let visionModel else {
            throw ImageClassificationError.underlying(ImageClassificationServiceInitializationError.failedToLoadModel)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error {
                    continuation.resume(throwing: ImageClassificationError.underlying(error))
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first else {
                    continuation.resume(throwing: ImageClassificationError.noResult)
                    return
                }

                let result = ClassificationResult(identifier: top.identifier, confidence: Double(top.confidence))
                continuation.resume(returning: result)
            }

            request.imageCropAndScaleOption = .centerCrop

            do {
                try VNImageRequestHandler(ciImage: ciImage).perform([request])
            } catch {
                continuation.resume(throwing: ImageClassificationError.underlying(error))
                return
            }
        }
    }
}

enum ImageClassificationServiceInitializationError: LocalizedError {
    case failedToLoadModel

    var errorDescription: String? {
        "Unable to load Core ML model."
    }
}
