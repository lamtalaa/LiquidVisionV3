//
//  AppCoordinator.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import Foundation

final class AppCoordinator: ObservableObject {
    private var registry = ViewModelCoordinatorRegistry()
    private var cachedViewModels: [ObjectIdentifier: Any] = [:]

    init(childCoordinators: [AnyViewModelCoordinator] = []) {
        childCoordinators.forEach { registry.store($0) }
        registerIfNeeded(ClassificationCoordinator())
        registerIfNeeded(SentimentCoordinator())
        registerIfNeeded(AudioAnalyzerCoordinator())
    }

    func register<C: ViewModelCoordinating>(_ coordinator: C) {
        registry.register(coordinator)
    }

    func viewModel<ViewModel>(_ type: ViewModel.Type) -> ViewModel {
        let key = ObjectIdentifier(type)

        if let cached = cachedViewModels[key] as? ViewModel {
            return cached
        }

        guard let viewModel = registry.resolve(type) else {
            preconditionFailure("No coordinator registered for \(type)")
        }

        cachedViewModels[key] = viewModel
        return viewModel
    }

    func viewModel<ViewModel>() -> ViewModel {
        viewModel(ViewModel.self)
    }

    private func registerIfNeeded<C: ViewModelCoordinating>(_ coordinator: C) {
        let identifier = ObjectIdentifier(C.ViewModel.self)

        guard registry.contains(identifier: identifier) == false else { return }
        registry.register(coordinator)
    }
}
