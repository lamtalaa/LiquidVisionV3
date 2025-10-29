//
//  AppCoordinatorTests.swift
//  LiquidVisionTests
//
//  Created by Yassine Lamtalaa on 11/24/25.
//

import XCTest
@testable import LiquidVision

final class AppCoordinatorTests: XCTestCase {
    func testViewModelReturnsCachedInstance() {
        let coordinator = AppCoordinator(childCoordinators: [AnyViewModelCoordinator(DummyCoordinator())])

        let first: DummyViewModel = coordinator.viewModel(DummyViewModel.self)
        let second: DummyViewModel = coordinator.viewModel(DummyViewModel.self)

        XCTAssertTrue(first === second)
    }

    func testRegisterAddsCoordinator() {
        let coordinator = AppCoordinator()
        coordinator.register(DummyCoordinator())

        let resolved: DummyViewModel = coordinator.viewModel(DummyViewModel.self)
        XCTAssertEqual(resolved.identifier, "dummy")
    }

    func testCoordinatorRegistryContainsAndResolve() {
        var registry = ViewModelCoordinatorRegistry()
        XCTAssertFalse(registry.contains(identifier: ObjectIdentifier(DummyViewModel.self)))

        registry.register(DummyCoordinator())
        XCTAssertTrue(registry.contains(identifier: ObjectIdentifier(DummyViewModel.self)))

        let resolved: DummyViewModel? = registry.resolve(DummyViewModel.self)
        XCTAssertEqual(resolved?.identifier, "dummy")
    }
}

private final class DummyViewModel: ObservableObject {
    let identifier = "dummy"
}

private final class DummyCoordinator: ViewModelCoordinating {
    typealias ViewModel = DummyViewModel

    func makeViewModel() -> DummyViewModel {
        DummyViewModel()
    }
}
