//
//  AudioAnalyzerCoordinator.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import Foundation

final class AudioAnalyzerCoordinator: ViewModelCoordinating {
    typealias ViewModel = AudioAnalyzerViewModel

    func makeViewModel() -> AudioAnalyzerViewModel {
        AudioAnalyzerViewModel()
    }
}
