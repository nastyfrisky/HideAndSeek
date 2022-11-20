//
//  ViewController.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 16.11.2022.
//

import UIKit
import CoreBluetooth
import AVFoundation
import Accelerate

final class ViewController: UIViewController {
    
    @IBOutlet var label: UILabel!
    
//    private let recorder = AudioRecorder()
    private let player = AudioPlayer()
    private let signalRecognizer = SignalRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let waveSamples = extractSamplesFromWavFile(
            fileData: try! Data(contentsOf: Bundle.main.url(forResource: "mainPattern", withExtension: "wav")!)
        )
        
        signalRecognizer.startRecognizer(pattern: waveSamples)
        signalRecognizer.delegate = self
    }
    
    private func generateWave(frequency: Float, samplesCount: Int, sampleRate: Float = 48000) -> [Float] {
        var result: [Float] = []
        
        for i in 0..<samplesCount {
            result.append(sin(frequency * 2 * Float.pi * Float(i) / Float(sampleRate)))
        }
        
        return result
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

extension ViewController: SignalRecognizerDelegate {
    func delayMeasured(delay: Int) {
        label.text = "\(delay)"
    }
}
