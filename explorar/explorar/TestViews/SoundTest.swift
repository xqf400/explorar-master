//
//  SoundTest.swift
//  explorar
//
//  Created by Fabian Kuschke on 12.08.25.
//

import SwiftUI
import AVFoundation

struct TTSTestView: View {
    @State private var textToSpeak = "Mein Haus wurde im 14. Jahrhundert erbaut und überblickt das Rheintal."
    @State private var isLoading = false
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    let name = "myaudio.mp3"
    
    class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
        var didFinish: () -> Void
        init(didFinish: @escaping () -> Void) {
            self.didFinish = didFinish
        }
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            didFinish()
        }
    }

    @State private var audioDelegate: AudioPlayerDelegate?
    
    
    func loadAudio() {
        let fileManager = FileManager.default
        if let docsDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let audioURL = docsDir.appendingPathComponent(name)
            do {
                player = try AVAudioPlayer(contentsOf: audioURL)
                let delegate = AudioPlayerDelegate {
                                    isPlaying = false
                                }
                player!.delegate = delegate
                audioDelegate = delegate
            } catch {
                print("Failed to load audio: \(error)")
            }
        }
    }
    
    func downloadAudio() {
        let docs = try! FileManager.default.url(for: .libraryDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        let fileURL = docs.appendingPathComponent(name)
        AIService.shared.downloadVoiceMp3(textToSpeak, to: fileURL) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let url):
                    print("Saved to:", url.path)
                    do {
                        player = try AVAudioPlayer(contentsOf: url)
                        let delegate = AudioPlayerDelegate {
                            isPlaying = false
                        }
                        audioDelegate = delegate
                        player!.delegate = delegate
                        player!.play()
                        isPlaying = true
                    } catch {
                        print("Playback error: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("TTS error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                if let player = player {
                    if isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                    isPlaying.toggle()
                }
            }) {
                Text(isPlaying ? "Pause" : "Play")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            TextField("Enter text…", text: $textToSpeak, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView("Generating speech…")
            }
            
            HStack {
                Button(isLoading ? "Working…" : "get Mp3") {
downloadAudio()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || textToSpeak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Spacer(minLength: 12)
        }
        .padding()
        .onAppear {
            loadAudio()
        }
    }
}
