//
//  CoordinatorRegistry.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/28/25.
//

import Foundation

protocol ViewModelCoordinating {
    associatedtype ViewModel
    func makeViewModel() -> ViewModel
}

struct AnyViewModelCoordinator {
    private let makeClosure: () -> Any
    let identifier: ObjectIdentifier

    init<C: ViewModelCoordinating>(_ coordinator: C) {
        makeClosure = coordinator.makeViewModel
        identifier = ObjectIdentifier(C.ViewModel.self)
    }

    func makeViewModel() -> Any {
        makeClosure()
    }
}

extension ViewModelCoordinating {
    func eraseToAnyCoordinator() -> AnyViewModelCoordinator {
        AnyViewModelCoordinator(self)
    }
}

struct ViewModelCoordinatorRegistry {
    private var storage: [ObjectIdentifier: AnyViewModelCoordinator] = [:]

    mutating func store(_ coordinator: AnyViewModelCoordinator) {
        storage[coordinator.identifier] = coordinator
    }

    mutating func register<C: ViewModelCoordinating>(_ coordinator: C) {
        store(AnyViewModelCoordinator(coordinator))
    }

    func contains(identifier: ObjectIdentifier) -> Bool {
        storage[identifier] != nil
    }

    func resolve<ViewModel>(_ type: ViewModel.Type) -> ViewModel? {
        guard let coordinator = storage[ObjectIdentifier(type)] else { return nil }
        return coordinator.makeViewModel() as? ViewModel
    }
}
