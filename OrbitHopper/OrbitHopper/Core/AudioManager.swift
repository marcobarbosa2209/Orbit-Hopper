//
//  AudioManager.swift
//  OrbitHopper
//

import AVFoundation
import Foundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var menuPlayer: AVAudioPlayer?
    
    private init() {
        setupMenuMusic()
    }
    
    private func setupMenuMusic() {
        guard let url = Bundle.main.url(forResource: "MenuMusic", withExtension: "wav") else {
            print("Could not find MenuMusic.wav")
            return
        }
        
        do {
            menuPlayer = try AVAudioPlayer(contentsOf: url)
            menuPlayer?.numberOfLoops = -1 // Loop indefinitely
            menuPlayer?.volume = 0.5
            menuPlayer?.prepareToPlay()
        } catch {
            print("Error loading MenuMusic: \(error.localizedDescription)")
        }
    }
    
    func playMenuMusic() {
        if let player = menuPlayer, !player.isPlaying {
            player.play()
        }
    }
    
    func pauseMenuMusic() {
        if let player = menuPlayer, player.isPlaying {
            player.pause()
        }
    }
}
