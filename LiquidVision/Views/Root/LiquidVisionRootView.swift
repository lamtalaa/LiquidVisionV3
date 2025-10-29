//
//  LiquidVisionRootView.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import SwiftUI

struct LiquidVisionRootView: View {
    @StateObject private var classificationViewModel: ClassificationViewModel
    @StateObject private var sentimentViewModel: SentimentViewModel
    @StateObject private var audioAnalyzerViewModel: AudioAnalyzerViewModel

    init(
        classificationViewModel: ClassificationViewModel,
        sentimentViewModel: SentimentViewModel,
        audioAnalyzerViewModel: AudioAnalyzerViewModel
    ) {
        _classificationViewModel = StateObject(wrappedValue: classificationViewModel)
        _sentimentViewModel = StateObject(wrappedValue: sentimentViewModel)
        _audioAnalyzerViewModel = StateObject(wrappedValue: audioAnalyzerViewModel)
    }

    var body: some View {
        TabView {
            ClassificationView(viewModel: classificationViewModel)
                .tabItem { Label("Vision", systemImage: "photo") }
                .tag(0)

            SentimentView(viewModel: sentimentViewModel)
                .tabItem { Label("Sentiment", systemImage: "text.quote") }
                .tag(1)

            AudioAnalyzerView(viewModel: audioAnalyzerViewModel)
                .tabItem { Label("Audio", systemImage: "waveform") }
                .tag(2)
        }
    }
}
