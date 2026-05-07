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
        // We can just overwrite this whenever they beat a level
        UserDefaults.standard.set(levelIndex, forKey: campaignLevelKey)
    }
}
