//
//  SpeechRecognizer.swift
//  PhiAI
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var transcribedText: String = ""

    /// 请求语音识别权限
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// 开始语音识别
    func startRecording() throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "RecognizerNotAvailable", code: 1)
        }

        // 清除之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil

        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            throw NSError(domain: "RequestCreationFailed", code: 2)
        }
        request.shouldReportPartialResults = true

        // 获取麦克风输入
        let inputNode = audioEngine.inputNode

        // 创建识别任务
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self?.stopRecording()
            }
        }

        // 安装音频输入 tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // 启动音频引擎
        audioEngine.prepare()
        try audioEngine.start()
    }

    /// 停止识别
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask = nil
        recognitionRequest = nil
    }
}
