//
//  UICoordinator.swift
//  xDripClientUI
//
//  Created by Julian Groen on 15/03/2022.
//  Copyright © 2022 Julian Groen. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import xDripClient


class UICoordinator: UINavigationController, CGMManagerOnboarding, CompletionNotifying, UINavigationControllerDelegate {
    
    let cgmManager: xDripCGMManager?
    let glucoseUnitObservable: DisplayGlucoseUnitObservable?
    let colorPalette: LoopUIColorPalette
    
    weak var cgmManagerOnboardingDelegate: CGMManagerOnboardingDelegate?
    weak var completionDelegate: CompletionDelegate?
    
    init(
        cgmManager: xDripCGMManager? = nil,
        glucoseUnitObservable: DisplayGlucoseUnitObservable? = nil,
        colorPalette: LoopUIColorPalette
    ) {
        self.colorPalette = colorPalette
        self.glucoseUnitObservable = glucoseUnitObservable
        self.cgmManager = cgmManager
        super.init(navigationBarClass: UINavigationBar.self, toolbarClass: UIToolbar.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.prefersLargeTitles = true
        delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let controller = viewController(willShow: .status)
        setViewControllers([controller], animated: false)
    }
    
    private enum ControllerType: Int, CaseIterable {
        case status
    }
    
    private func viewController(willShow view: ControllerType) -> UIViewController {
        switch view {
        case .status:
            guard let cgmManager = cgmManager, let observable = glucoseUnitObservable else {
                fatalError()
            }
            let model = xDripStatusModel(cgmManager: cgmManager, for: observable)
            model.hasCompleted = { [weak self] in
                self?.notifyCompletion()
            }
            let view = xDripStatusView(viewModel: model)

            return viewController(rootView: view)
        }
    }
    
    
    private func viewController<Content: View>(rootView: Content) -> DismissibleHostingController {
        return DismissibleHostingController(rootView: rootView, colorPalette: colorPalette)
    }
    
    private func setupCompletion(_ cgmManager: xDripCGMManager) {
        cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
        completionDelegate?.completionNotifyingDidComplete(self)
    }
    
    private func notifyCompletion() {
        completionDelegate?.completionNotifyingDidComplete(self)
    }
}
