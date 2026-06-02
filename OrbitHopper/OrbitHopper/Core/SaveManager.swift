//
//  SaveManager.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 07/05/2026.
//

import Foundation

struct SaveManager {
    
    // 1. Define exact string keys so we don't make typos later
    private static let highScoreKey = "endless_hi_score"
    private static let campaignLevelKey = "campaign_current_level"
    private static let musicVolumeKey = "settings_music_volume"
    private static let sfxVolumeKey = "settings_sfx_volume"
    
    // MARK: - Endless Mode
    static func getHighScore() -> Int {
        // If no score exists yet, UserDefaults automatically returns 0
        return UserDefaults.standard.integer(forKey: highScoreKey)
    }
    
    static func saveHighScore(newScore: Int) {
        let currentHigh = getHighScore()
        
        // Only save if the new score is higher
        if newScore > currentHigh {
            UserDefaults.standard.set(newScore, forKey: highScoreKey)
        }
    }
    
    // MARK: - Campaign Mode
    static func getCurrentLevelIndex() -> Int {
        return UserDefaults.standard.integer(forKey: campaignLevelKey)
    }
    
    static func saveLevelProgress(levelIndex: Int) {
        let current = getCurrentLevelIndex()
        // Only save if the new level is further than what we've unlocked
        if levelIndex > current {
            UserDefaults.standard.set(levelIndex, forKey: campaignLevelKey)
        }
    }
    
    // MARK: - Per-Level Stars
    static func getStars(forLevel index: Int) -> Int {
        return UserDefaults.standard.integer(forKey: "level_\(index)_stars")
    }
    
    static func saveStars(forLevel index: Int, stars: Int) {
        let currentBest = getStars(forLevel: index)
        // Only save if new star count is higher
        if stars > currentBest {
            UserDefaults.standard.set(stars, forKey: "level_\(index)_stars")
        }
    }
    
    // MARK: - Settings (Persistent)
    static func getMusicVolume() -> Float {
        let val = UserDefaults.standard.object(forKey: musicVolumeKey)
        // Default to 75% if never set
        return (val as? Float) ?? 0.75
    }
    
    static func saveMusicVolume(_ volume: Float) {
        UserDefaults.standard.set(volume, forKey: musicVolumeKey)
    }
    
    static func getSFXVolume() -> Float {
        let val = UserDefaults.standard.object(forKey: sfxVolumeKey)
        // Default to 90% if never set
        return (val as? Float) ?? 0.90
    }
    
    static func saveSFXVolume(_ volume: Float) {
        UserDefaults.standard.set(volume, forKey: sfxVolumeKey)
    }
}
