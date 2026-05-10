//
//  AdManager.swift
//  OrbitHopper
//
//  Created by Marco Barbosa on 10/05/2026.
//

import Foundation
import SwiftUI
import Combine
import GoogleMobileAds

class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    
    @Published var isInitialized: Bool = false
    
    private var rewardedAd: RewardedAd?
    var gameState: GameState?
    
    // 1. Anti-cheat tracker to prevent rewards on early close
    private var playerEarnedReward = false
    
    // 2. Test ID for development (replace with real ID for production)
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    func initialize() {
        // 1. Initialize AdMob SDK and load the first ad
        MobileAds.shared.start { [weak self] _ in
            print("AdMob SDK initialized.")
            DispatchQueue.main.async {
                self?.isInitialized = true
                self?.loadAd()
            }
        }
    }
    
    func loadAd() {
        // 1. Prevent loading before SDK is ready
        guard isInitialized else {
            print("AdMob SDK not ready yet, skipping ad load.")
            return
        }
        
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load ad: \(error.localizedDescription)")
                DispatchQueue.main.async { self?.gameState?.isAdReady = false }
                return
            }
            
            print("Rewarded ad loaded successfully.")
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            
            // 2. Notify UI that the ad is ready to watch
            DispatchQueue.main.async { self?.gameState?.isAdReady = true }
        }
    }
    
    func showAd(from rootViewController: UIViewController) {
        guard let ad = rewardedAd else { return }
        
        // 1. Reset tracker before presenting
        playerEarnedReward = false
        
        ad.present(from: rootViewController) { [weak self] in
            // 2. Handle reward event (player watched enough)
            print("Reward earned!")
            self?.playerEarnedReward = true
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        // 1. Handle ad dismissal and check for reward eligibility
        if playerEarnedReward {
            // 2. Resurrection sequence
            DispatchQueue.main.async { self.gameState?.triggerResurrection = true }
        } else {
            print("Ad closed early. No reward.")
        }
        
        // 3. Reset ad state and load the next one silently
        DispatchQueue.main.async { self.gameState?.isAdReady = false }
        loadAd()
    }
}

