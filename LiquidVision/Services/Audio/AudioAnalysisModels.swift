//
//  AudioAnalysisModels.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import Foundation

struct AudioClassificationResult: Equatable, Codable {
    let identifier: String
    let confidence: Double
}

enum AudioAnalysisSource: String, Codable {
    case file
    case live
}

struct AudioAnalysisLogEntry: Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let source: AudioAnalysisSource
    let transcription: String
    let classifications: [AudioClassificationResult]
}

struct AudioFileAnalysisResult: Equatable {
    let transcription: String
    let classifications: [AudioClassificationResult]
}
