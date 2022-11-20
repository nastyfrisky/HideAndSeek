//
//  HideViewController.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit
import AVFoundation

final class HiderViewController: UIViewController {
    private let centralManager: CentralManagerService = CentralManagerServiceImpl()
    
    private var peripheralManager: PeripheralManagerService?
    private var audioPlayer: AVAudioPlayer?
    
    private let stackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 8
        view.axis = .vertical
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Я прячусь"
        
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        stackView.addArrangedSubview(makeSelectItem(
            text: "Включить передатчик",
            action: #selector(bluetoothChanged)
        ))
        
        stackView.addArrangedSubview(makeSelectItem(
            text: "Включить звуки птиц",
            action: #selector(soundChanged)
        ))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        super.viewDidDisappear(animated)
    }
    
    private func makeSelectItem(text: String, action: Selector) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        
        let label = UILabel()
        label.text = text
        
        let switchItem = UISwitch()
        switchItem.addTarget(self, action: action, for: .valueChanged)
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(switchItem)
        
        return stackView
    }
    
    @objc private func bluetoothChanged(sender: UISwitch) {
        if sender.isOn {
            peripheralManager = PeripheralManagerService()
        } else {
            peripheralManager = nil
        }
    }
    
    @objc private func soundChanged(sender: UISwitch) {
        if sender.isOn {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback)
            try? session.setActive(true)
            let fileURL = Bundle.main.url(forResource: "pattern", withExtension: "mp3")!
            audioPlayer = try? AVAudioPlayer(contentsOf: fileURL)
            guard let audioPlayer = audioPlayer else { return }
            audioPlayer.volume = 1
            audioPlayer.numberOfLoops = .max
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } else {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
}
