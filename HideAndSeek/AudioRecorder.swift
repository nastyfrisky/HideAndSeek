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
        
        do {
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            fatalError("Failed to configure and activate session.")
        }
        
        guard let availableInputs = audioSession.availableInputs,
              let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
            print("The device must have a built-in microphone.")
            return
        }
        
        do {
            try audioSession.setPreferredInput(builtInMicInput)
        } catch {
            print("Unable to set the built-in mic as the preferred input.")
        }
        
//        guard let preferredInput = audioSession.preferredInput,
//              let dataSources = preferredInput.dataSources else { return }
//
//        dataSources.forEach { print($0) }
        
        guard let preferredInput = audioSession.preferredInput,
              let dataSources = preferredInput.dataSources,
              let newDataSource = dataSources.first(where: { $0.dataSourceName == "Впереди" }),
              let supportedPolarPatterns = newDataSource.supportedPolarPatterns else {
            print("No datasources")
            return
        }

        do {
            if supportedPolarPatterns.contains(.stereo) {
                try newDataSource.setPreferredPolarPattern(.stereo)
            }

            try preferredInput.setPreferredDataSource(newDataSource)

            try audioSession.setPreferredInputOrientation(.portrait)

        } catch {
            fatalError("Unable to select data source.")
        }
        
        
        let format = engine.inputNode.outputFormat(forBus: 0)
        
        print(format.channelCount)
        print(format.sampleRate)
        print(String(describing: format.commonFormat))
        print(format.isInterleaved)
        
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
