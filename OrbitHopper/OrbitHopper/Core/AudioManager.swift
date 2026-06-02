//
//  AudioManager.swift
//  OrbitHopper
//

import AVFoundation
import Foundation
import Combine

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var menuPlayer: AVAudioPlayer?
    
    @Published var musicVolume: Float = SaveManager.getMusicVolume() {
        didSet {
            menuPlayer?.volume = musicVolume
            SaveManager.saveMusicVolume(musicVolume)
        }
    }
    
    @Published var sfxVolume: Float = SaveManager.getSFXVolume() {
        didSet {
            SaveManager.saveSFXVolume(sfxVolume)
        }
    }
    
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
            menuPlayer?.volume = musicVolume
            menuPlayer?.prepareToPlay()
        } catch {
            print("Error loading MenuMusic: \(error.localizedDescription)")
        }
    }
    
    func playMenuMusic() {
        if let player = menuPlayer, !player.isPlaying {
            player.volume = musicVolume
            player.play()
        }
    }
    
    func pauseMenuMusic() {
        if let player = menuPlayer, player.isPlaying {
            player.pause()
        }
    }
}
