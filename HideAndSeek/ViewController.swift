//
//  ViewController.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 16.11.2022.
//

import UIKit

final class ViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        
        let viewController = ModeSelectionViewController()
        viewController.delegate = self
        pushViewController(viewController, animated: false)
    }
}

extension ViewController: ModeSelectionViewControllerDelegate {
    func didSelectedMode(mode: AppMode) {
        switch mode {
        case .searcher:
            let viewController = SearcherViewController()
            pushViewController(viewController, animated: true)
        case .hider:
            let viewController = HiderViewController()
            pushViewController(viewController, animated: true)
        }
    }
}
