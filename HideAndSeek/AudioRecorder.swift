//
//  AudioRecorder.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 16.11.2022.
//

import AVFoundation

final class AudioRecorder {
    private let engine = AVAudioEngine()
    
    func startRecord(onPacket: @escaping (AVAudioPCMBuffer) -> Void) {
        
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.set
        
        let format = engine.inputNode.outputFormat(forBus: 0)
        let bufferSize: UInt32 = 4000
        
        engine.inputNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: format
        ) { buffer, time in
            onPacket(buffer)
        }
        
        try? engine.start()
    }
    
    func stopRecord() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
    }
}
