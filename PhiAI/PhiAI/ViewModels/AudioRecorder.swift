//
//  AudioRecorder.swift
//  PhiAI
//

import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var recordedURL: URL?

    func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let filename = UUID().uuidString + ".m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordedURL = url
        } catch {
            print("录音失败: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
}


class AudioPlayerHelper: ObservableObject {
    static let shared = AudioPlayerHelper()
    private var player: AVPlayer?

    @Published var isPlaying: Bool = false

    func playAudio(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("无效音频URL")
            return
        }
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true

        // 监听播放结束
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem, queue: .main) { [weak self] _ in
            self?.isPlaying = false
        }
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
    }
}

