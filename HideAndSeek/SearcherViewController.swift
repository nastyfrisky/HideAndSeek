//
//  SearchViewController.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import UIKit
import CoreMotion

final class SearcherViewController: UIViewController {
    
    private let signalRecognizer = SignalRecognizer()
    private let motionManager = CMMotionManager()
    private let centralManager: CentralManagerService = CentralManagerServiceImpl()
    
    private var bluetoothCounter = 0
    private var bluetoothDistance = 0
    private var isNeededSetCircleRadius = true
    
    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .init(white: 0.9, alpha: 1.0)
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }()
    
    private let arrowView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = .systemRed
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        return view
    }()
    
    private let soundSearchLabel: UILabel = {
        let label = UILabel()
        label.text = "Поиск по звуку птиц"
        label.textAlignment = .center
        return label
    }()
    
    private let bluetoothSearchLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Поиск по bluetooth..."
        return label
    }()
    
    private var currentYaw: Double = 0
    private var targetAngle: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Я ищу"
        
        signalRecognizer.delegate = self
        centralManager.delegate = self
        
        [circleView, soundSearchLabel, bluetoothSearchLabel].forEach { view.addSubview($0) }
        circleView.addSubview(arrowView)
        
        [circleView, arrowView, soundSearchLabel, bluetoothSearchLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            bluetoothSearchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bluetoothSearchLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bluetoothSearchLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            soundSearchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            soundSearchLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            soundSearchLabel.bottomAnchor.constraint(equalTo: circleView.topAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            circleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            circleView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            circleView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            arrowView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            arrowView.topAnchor.constraint(equalTo: circleView.topAnchor),
            arrowView.bottomAnchor.constraint(equalTo: circleView.centerYAnchor, constant: 10)
        ])
        
        motionManager.startDeviceMotionUpdates(
            using: .xMagneticNorthZVertical,
            to: .main,
            withHandler: { [weak self] data, error in
                guard let data = data else { return }
                self?.currentYaw = data.attitude.yaw
                self?.updateDirection()
            }
        )
        
        signalRecognizer.startRecognizer(
            pattern: extractSamplesFromWavFile(
                fileData: try! Data(contentsOf: Bundle.main.url(forResource: "mainPattern", withExtension: "wav")!)
            )
        )
    }
    
    override func viewDidLayoutSubviews() {
        if isNeededSetCircleRadius {
            isNeededSetCircleRadius = false
            circleView.layer.cornerRadius = circleView.frame.height / 2
        }
        super.viewDidLayoutSubviews()
    }
    
    private func updateDirection() {
        circleView.transform = CGAffineTransform(rotationAngle: targetAngle + currentYaw)
    }
    
    private func extractSamplesFromWavFile(fileData: Data) -> [Float] {
        let samplesCount = (fileData.count - 500) / 2
        
        let fileData = Array(fileData.dropFirst(500))
        
        var result: [Float] = []
        
        for i in 0..<samplesCount {
            let ampUInt = UInt(fileData[i * 2]) + UInt(fileData[i * 2 + 1]) * 256
            let ampInt = Int16(bitPattern: UInt16(ampUInt))
            
            result.append(Float(ampInt) / 32768)
        }
        
        return result
    }
}

extension SearcherViewController: SignalRecognizerDelegate {
    func delayMeasured(delay: Int) {
        if delay > 10 {
            targetAngle = currentYaw
        } else if delay < -10 {
            targetAngle = -currentYaw
        }
    }
}

extension SearcherViewController: CentralManagerServiceDelegate {
    func didUpdateRSSI(rssi: Int) {
        let power = (-55 - Double(rssi)) / 20
        let distance = Int(pow(10, power))
        
        if bluetoothCounter % 30 == 0 {
            bluetoothSearchLabel.text = "Примерное расстояние до передатчика: \(bluetoothDistance / 30) метров"
            bluetoothDistance = 0
        }
        
        bluetoothDistance += distance
        bluetoothCounter += 1
    }
}
