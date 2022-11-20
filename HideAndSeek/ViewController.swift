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
    
    private let recorder = AudioRecorder()
    private let player = AudioPlayer()
    
    private lazy var pattern = generateWave(frequency: 440, samplesCount: 1000)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var counter = 0
        
        recorder.startRecord { [weak self] buffer in
            counter += 1
            guard counter >= 3 else { return }
            
            self?.recorder.stopRecord()
            
            print("frames count = \(buffer.frameLength)")
            
            print("CH1")
            for i in 0..<220 {
                print("\(buffer.floatChannelData!.pointee[i]),")
            }
            
            print("")
            print("CH2")
            for i in 0..<220 {
                print("\(buffer.floatChannelData!.pointee[Int(buffer.frameLength) + i]),")
            }
            
        }
    }
    
    private func normalizedSignal(signal: [Float]) -> [Float] {
        let max = signal.map { abs($0) }.max()!
        return signal.map { $0 / max }
    }
    
    private func signalPower(signal: [Float]) -> Float {
        var power = signal[0]
        for i in 1..<signal.count {
            power += abs(signal[i])
            power /= 2
        }
        
        return power
    }
    
    private func makeCorrelationFunction(
        signal: [Float],
        snapshot: [(offset: Int, value: Float)],
        patternLength: Int
    ) -> [Float] {
        var result: [Float] = []
        
        let functionLength = signal.count + patternLength - 1
        
        for i in 0..<functionLength {
            result.append(correlationPoint(
                signal: signal,
                snapshot: snapshot,
                patternStart: i - patternLength + 1
            ))
        }
        
        return result
    }
    
    private func correlationPoint(
        signal: [Float],
        snapshot: [(offset: Int, value: Float)],
        patternStart: Int
    ) -> Float {
        var result: Double = 0
    
        let regionStart = max(0, patternStart)
        
        snapshot.forEach {
            let position = regionStart + $0.offset
            guard position < signal.count else { return }
            result += Double(signal[regionStart + $0.offset]) * Double($0.value)
        }
        
        return Float(result)
    }
    
    private func makeCorrelationFunction(signal: [Float], pattern: [Float]) -> [Float] {
        var result: [Float] = []
        
        let functionLength = signal.count + pattern.count - 1
        
        for i in 0..<functionLength {
            result.append(correlationPoint(
                signal: signal,
                pattern: pattern,
                patternStart: i - pattern.count + 1
            ))
        }
        
        return result
    }
    
    private func correlationPoint(signal: [Float], pattern: [Float], patternStart: Int) -> Float {
        var result: Double = 0
        
        let patternEnd = patternStart + pattern.count - 1
        let regionStart = max(0, patternStart)
        let regionEnd = min(signal.count - 1, patternEnd)
        
        for i in regionStart...regionEnd {
            result += Double(signal[i]) * Double(pattern[i - patternStart])
        }
        
        return Float(result)
    }
    
    private func generateWave(frequency: Float, samplesCount: Int, sampleRate: Float = 44100) -> [Float] {
        var result: [Float] = []
        
        for i in 0..<samplesCount {
            result.append(sin(frequency * 2 * Float.pi * Float(i) / Float(sampleRate)))
        }
        
        return result
    }

    private func testPlay(soundSamples: [Float]) {
        let framesCount = AVAudioFrameCount(soundSamples.count)
        
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)
        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: framesCount)!
        pcmBuffer.frameLength = framesCount
        
        for i in 0..<soundSamples.count {
            pcmBuffer.floatChannelData!.pointee[i] = soundSamples[i]
        }
        
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
        player.play(buffer: pcmBuffer)
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

    // MARK: Convolution
    // Convolution of a signal [x], with a kernel [k]. The signal must be at least as long as the kernel.
    public func conv(_ x: [Float], _ k: [Float]) -> [Float] {
        precondition(x.count >= k.count, "Input vector [x] must have at least as many elements as the kernel,  [k]")
        
        let resultSize = x.count + k.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let kEnd = UnsafePointer<Float>(k).advanced(by: k.count - 1)
        let xPad = repeatElement(Float(0.0), count: k.count-1)
        let xPadded = xPad + x + xPad
        vDSP_conv(xPadded, 1, kEnd, -1, &result, 1, vDSP_Length(resultSize), vDSP_Length(k.count))
        
        return result
    }

    // Convolution of a signal [x], with a kernel [k]. The signal must be at least as long as the kernel.
    public func conv(_ x: [Double], _ k: [Double]) -> [Double] {
        precondition(x.count >= k.count, "Input vector [x] must have at least as many elements as the kernel,  [k]")
        
        let resultSize = x.count + k.count - 1
        var result = [Double](repeating: 0, count: resultSize)
        let kEnd = UnsafePointer<Double>(k).advanced(by: k.count - 1)
        let xPad = repeatElement(Double(0.0), count: k.count-1)
        let xPadded = xPad + x + xPad
        vDSP_convD(xPadded, 1, kEnd, -1, &result, 1, vDSP_Length(resultSize), vDSP_Length(k.count))
        
        return result
    }

    // MARK: Cross-Correlation
    // Cross-correlation of a signal [x], with another signal [y]. The signal [y]
    // is padded so that it is the same length as [x].
    public func xcorr(_ x: [Float], _ y: [Float]) -> [Float] {
        precondition(x.count >= y.count, "Input vector [x] must have at least as many elements as [y]")
        var yPadded = y
        if x.count > y.count {
            let padding = repeatElement(Float(0.0), count: x.count - y.count)
            yPadded = y + padding
        }
        
        let resultSize = x.count + yPadded.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let xPad = repeatElement(Float(0.0), count: yPadded.count-1)
        let xPadded = xPad + x + xPad
        vDSP_conv(xPadded, 1, yPadded, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(yPadded.count))
        
        return result
    }

    // Cross-correlation of a signal [x], with another signal [y]. The signal [y]
    // is padded so that it is the same length as [x].
    public func xcorr(_ x: [Double], _ y: [Double]) -> [Double] {
        precondition(x.count >= y.count, "Input vector [x] must have at least as many elements as [y]")
        var yPadded = y
        if x.count > y.count {
            let padding = repeatElement(Double(0.0), count: x.count - y.count)
            yPadded = y + padding
        }
        
        let resultSize = x.count + yPadded.count - 1
        var result = [Double](repeating: 0, count: resultSize)
        let xPad = repeatElement(Double(0.0), count: yPadded.count-1)
        let xPadded = xPad + x + xPad
        vDSP_convD(xPadded, 1, yPadded, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(yPadded.count))
        
        return result
    }

    // MARK: Auto-correlation
    // Auto-correlation of a signal [x]
    public func xcorr(_ x: [Float]) -> [Float] {
        let resultSize = 2*x.count - 1
        var result = [Float](repeating: 0, count: resultSize)
        let xPad = repeatElement(Float(0.0), count: x.count-1)
        let xPadded = xPad + x + xPad
        vDSP_conv(xPadded, 1, x, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(x.count))
        
        return result
    }

    // Auto-correlation of a signal [x]
    public func xcorr(_ x: [Double]) -> [Double] {
        let resultSize = 2*x.count - 1
        var result = [Double](repeating: 0, count: resultSize)
        let xPad = repeatElement(Double(0.0), count: x.count-1)
        let xPadded = xPad + x + xPad
        vDSP_convD(xPadded, 1, x, 1, &result, 1, vDSP_Length(resultSize), vDSP_Length(x.count))
        
        return result
    }
}
