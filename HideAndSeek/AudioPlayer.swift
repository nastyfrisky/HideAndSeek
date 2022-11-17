//
//  AudioPlayer.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 16.11.2022.
//

import AVFoundation

final class AudioPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
        try? audioSession.setActive(true)
    }
    
    private func setupPlayer(buffer: AVAudioPCMBuffer) {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: buffer.format)
        engine.prepare()
    }
    
    func play(buffer: AVAudioPCMBuffer) {
        if !engine.isRunning {
            setupPlayer(buffer: buffer)
            try? engine.start()
            playerNode.play()
        }

        playerNode.volume = 1
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }
}
