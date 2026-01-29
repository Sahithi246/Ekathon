//
//  VoiceRecorder.swift
//  HackathonApp
//
//  Created on 29/01/26.
//

import Foundation
import AVFoundation
import Combine

class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentAmplitude: Double = 0.5
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var timer: Timer?
    private var startTime: Date?
    private var recordingURL: URL?
    
    struct RecordingResult {
        let url: URL
        let duration: TimeInterval
        let transcription: String?
    }
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func start() {
        guard !isRecording else { return }
        
        // Request microphone permission
        audioSession.requestRecordPermission { [weak self] granted in
            guard granted, let self = self else {
                print("Microphone permission denied")
                return
            }
            
            DispatchQueue.main.async {
                self.startRecording()
            }
        }
    }
    
    private func startRecording() {
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        guard let url = recordingURL else { return }
        
        // Audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            startTime = Date()
            elapsedTime = 0
            
            // Start timer
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateTimer()
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stop(completion: ((RecordingResult) -> Void)? = nil) {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        guard let url = recordingURL,
              let startTime = startTime else {
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // For demo purposes, we'll use mock transcription
        // In production, you'd integrate with Speech framework or EkaScribe API
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isProcessing = false
            
            let result = RecordingResult(
                url: url,
                duration: duration,
                transcription: nil // Will be generated in VoiceCheckView
            )
            
            completion?(result)
        }
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
        
        // Update amplitude for visualization
        audioRecorder?.updateMeters()
        if let recorder = audioRecorder {
            let normalizedPower = pow(10, recorder.averagePower(forChannel: 0) / 20)
          currentAmplitude = Double(min(1.0, max(0.0, normalizedPower)))
        }
        
        // Auto-stop at 60 seconds
        if elapsedTime >= 60.0 {
            stop()
        }
    }
}

extension VoiceRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}
