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
        
        let patternCount = patternSamples.count
        let doublePatternCount = patternCount * 2
        while leftChannelSamples.count >= doublePatternCount {
            let leftSamples = Array(leftChannelSamples.prefix(doublePatternCount))
            let rightSamples = Array(rightChannelSamples.prefix(doublePatternCount))
            leftChannelSamples = Array(leftChannelSamples.dropFirst(patternCount))
            rightChannelSamples = Array(rightChannelSamples.dropFirst(patternCount))
            analyzeSamples(leftSamples: leftSamples, rightSamples: rightSamples)
        }
    }
    
    private func analyzeSamples(leftSamples: [Float], rightSamples: [Float]) {
        let normLeftSamples = leftSamples.map { $0 }
        let normRightSamples = rightSamples.map { $0 }
        
        let leftCorr = xcorr(normLeftSamples, patternSamples)
        let rightCorr = xcorr(normRightSamples, patternSamples)
        
        let pickCount = 20
        let sortedLeftCorr = zip(leftCorr, (0..<leftCorr.count)).sorted { $0.0 < $1.0 }.suffix(pickCount)
        let sortedRightCorr = zip(rightCorr, (0..<rightCorr.count)).sorted { $0.0 < $1.0 }.suffix(pickCount)
        
        var pairs: [(Int, Int)] = []
        
        sortedLeftCorr.forEach { leftCorrElement in
            sortedRightCorr.forEach { rightCorrElement in
                if abs(leftCorrElement.1 - rightCorrElement.1) <= 22 {
                    pairs.append((leftCorrElement.1, rightCorrElement.1))
                }
            }
        }
        
        let sortedPairs = pairs.sorted { a, b in
            abs(leftCorr[a.0] * rightCorr[a.1]) > abs(leftCorr[b.0] * rightCorr[b.1])
        }
        
        if let pair = sortedPairs.first {
            DispatchQueue.main.async {
                self.delegate?.delayMeasured(delay: pair.0 - pair.1)
            }
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
        return signal.map { $0 / max * 1000 }
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

}
