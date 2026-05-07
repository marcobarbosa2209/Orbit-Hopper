import SwiftUI
import SpriteKit

struct ContentView: View {

    var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 300, height: 600)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
