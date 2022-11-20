//
//  ModeSelectionViewController.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit

enum AppMode {
    case hider
    case searcher
}

protocol ModeSelectionViewControllerDelegate: AnyObject {
    func didSelectedMode(mode: AppMode)
}

final class ModeSelectionViewController: UIViewController {
    weak var delegate: ModeSelectionViewControllerDelegate?
    
    private let contentView: UIStackView = {
        let view = UIStackView()
        view.spacing = 16
        view.axis = .vertical
        return view
    }()
    
    private lazy var searchButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Я ищу", for: .normal)
        return button
    }()
    
    private lazy var hideButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(hiderButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle("Я прячусь", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Выберите режим работы"
        
        [contentView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        contentView.addArrangedSubview(searchButton)
        contentView.addArrangedSubview(hideButton)
    }
    
    @objc private func searchButtonTapped() {
        delegate?.didSelectedMode(mode: .searcher)
    }
    
    @objc private func hiderButtonTapped() {
        delegate?.didSelectedMode(mode: .hider)
    }
}
