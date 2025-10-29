//
//  ClassificationCoordinator.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import Foundation

final class ClassificationCoordinator: ViewModelCoordinating {
    typealias ViewModel = ClassificationViewModel

    private let classifier: ImageClassificationServicing
    private let sentimentService: SentimentAnalysisServicing

    init(
        classifier: ImageClassificationServicing = MobileNetImageClassifier(),
        sentimentService: SentimentAnalysisServicing = SentimentAnalysisService()
    ) {
        self.classifier = classifier
        self.sentimentService = sentimentService
    }

    func makeViewModel() -> ClassificationViewModel {
        ClassificationViewModel(
            classifier: classifier,
            sentimentService: sentimentService
        )
    }
}
