//
//  SignalRecognizer.swift
//  HideAndSeek
//
//  Created by Анастасия Ступникова on 20.11.2022.
//

import AVFoundation
import Accelerate

protocol SignalRecognizerDelegate: AnyObject {
    func delayMeasured(delay: Int)
}

final class SignalRecognizer {
    weak var delegate: SignalRecognizerDelegate?
    
    private let audioRecorder = AudioRecorder()
    private var patternSamples: [Float] = []
    
    private var isStarted = false
    
    private var leftChannelSamples: [Float] = []
    private var rightChannelSamples: [Float] = []
    
    private var detectionsDifference: [Int] = []
    
    func startRecognizer(pattern: [Float]) {
        guard !isStarted else { return }
        patternSamples = normalizedSignal(signal: pattern)
        isStarted = true
        
        audioRecorder.startRecord { [weak self] buffer in
            self?.onBuffer(buffer: buffer)
        }
    }
    
    func stopRecognizer() {
        guard isStarted else { return }
        isStarted = false
        audioRecorder.stopRecord()
        leftChannelSamples = []
        rightChannelSamples = []
    }
    
    private func onBuffer(buffer: AVAudioPCMBuffer) {
        for i in 0..<buffer.frameLength {
            leftChannelSamples.append(buffer.floatChannelData!.pointee[Int(i)])
            rightChannelSamples.append(buffer.floatChannelData!.pointee[Int(i + buffer.frameLength)])
        }
        
        let doublePatternCount = patternSamples.count * 2
        while leftChannelSamples.count >= doublePatternCount {
            let leftSamples = Array(leftChannelSamples.prefix(doublePatternCount))
            let rightSamples = Array(rightChannelSamples.prefix(doublePatternCount))
            leftChannelSamples = Array(leftChannelSamples.dropFirst(patternSamples.count))
            rightChannelSamples = Array(rightChannelSamples.dropFirst(patternSamples.count))
            analyzeSamples(leftSamples: leftSamples, rightSamples: rightSamples)
        }
    }
    
    private func analyzeSamples(leftSamples: [Float], rightSamples: [Float]) {
        let normLeftSamples = normalizedSignal(signal: leftSamples)
        let normRightSamples = normalizedSignal(signal: rightSamples)
        
        let leftCorr = xcorr(normLeftSamples, patternSamples)
        let rightCorr = xcorr(normRightSamples, patternSamples)
        
        let leftIndex = maxAbsValueIndex(signal: leftCorr)
        let rightIndex = maxAbsValueIndex(signal: rightCorr)
        
        detectionsDifference.append(leftIndex - rightIndex)
        
        if detectionsDifference.count == 100 {
            
            print("L_CH")
            var i = 0
            normLeftSamples.forEach {
                if !$0.isNaN {
                    print("(\(i);\($0))")
                }
                
                i += 1
            }
            
            print("")
            print("R_CH")
            i = 0
            normRightSamples.forEach {
                if !$0.isNaN {
                    print("(\(i);\($0))")
                }
                
                i += 1
            }
            
            fatalError()
            
            let common = common(values: detectionsDifference)

            DispatchQueue.main.async { [weak self] in
                self?.delegate?.delayMeasured(delay: common)
            }

            detectionsDifference.removeAll(keepingCapacity: true)
        }
    }
    
    private func xcorr(_ x: [Float], _ y: [Float]) -> [Float] {
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
    
    private func normalizedSignal(signal: [Float]) -> [Float] {
        let max = signal.map { abs($0) }.max()!
        return signal.map { $0 / max }
    }
    
    private func middleAbsValue(signal: [Float]) -> Float {
        signal.map { abs($0) }.reduce(0, +) / Float(signal.count)
    }
    
    private func maxAbsValueIndex(signal: [Float]) -> Int {
        var index = 0
        for i in 1..<signal.count {
            if abs(signal[i]) > abs(signal[index]) {
                index = i
            }
        }
        
        return index
    }
    
    private func maxAbsValue(signal: [Float]) -> Float {
        signal.map { abs($0) }.max()!
    }
    
    private func common(values: [Int]) -> Int {
        let sorted = values.sorted()
        
        var number = sorted[0]
        var count = 1
        
        var currentCount = 1
        
        for i in 1..<sorted.count {
            if sorted[i] != sorted[i - 1] {
                if currentCount > count {
                    number = sorted[i - 1]
                    count = currentCount
                }
                
                currentCount = 1
            } else {
                currentCount += 1
            }
        }
        
        return number
    }
}
