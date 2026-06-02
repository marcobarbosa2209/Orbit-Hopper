//
//  SettingsView.swift
//  OrbitHopper
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var audioManager: AudioManager
    
    @State private var musicVolume: Float = SaveManager.getMusicVolume()
    @State private var sfxVolume: Float = SaveManager.getSFXVolume()
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // 1. Blurred backdrop
            Color.black.opacity(0.88)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // 2. Settings panel
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("SETTINGS")
                        .font(DS.orbitron(16))
                        .foregroundColor(.white)
                        .tracking(3)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.system(size: 15))
                            .foregroundColor(DS.red)
                            .frame(width: 34, height: 34)
                            .background(DS.red.opacity(0.08))
                            .clipShape(SciFiClipShape(cornerSize: 6))
                            .overlay(SciFiClipShape(cornerSize: 6).stroke(DS.red.opacity(0.35), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)
                
                Divider().background(DS.green.opacity(0.15))
                
                // 3. Music Volume
                VStack(spacing: 10) {
                    HStack {
                        HStack(spacing: 8) {
                            Text("🎵")
                                .font(.system(size: 16))
                            Text("MUSIC VOLUME")
                                .font(DS.mono(10))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(musicVolume * 100))%")
                            .font(DS.orbitron(12))
                            .foregroundColor(DS.green)
                    }
                    
                    Slider(value: $musicVolume, in: 0...1)
                        .accentColor(DS.green)
                        .onChange(of: musicVolume) { newValue in
                            audioManager.musicVolume = newValue
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider().background(DS.green.opacity(0.08))
                
                // 4. SFX Volume
                VStack(spacing: 10) {
                    HStack {
                        HStack(spacing: 8) {
                            Text("🔊")
                                .font(.system(size: 16))
                            Text("SFX VOLUME")
                                .font(DS.mono(10))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(sfxVolume * 100))%")
                            .font(DS.orbitron(12))
                            .foregroundColor(DS.green)
                    }
                    
                    Slider(value: $sfxVolume, in: 0...1)
                        .accentColor(DS.green)
                        .onChange(of: sfxVolume) { newValue in
                            audioManager.sfxVolume = newValue
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // 5. Back button
                VStack {
                    SciFiButton("BACK TO GAME", icon: "◀", style: .secondary) {
                        dismiss()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
            .frame(width: 340)
            .background(Color(red: 3/255, green: 12/255, blue: 24/255).opacity(0.97))
            .clipShape(SciFiClipShape())
            .overlay(SciFiClipShape().stroke(DS.green.opacity(0.35), lineWidth: 1))
            .overlay(CornerAccents(color: DS.green))
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            gameState.currentMenu = .mainMenu
        }
    }
}
