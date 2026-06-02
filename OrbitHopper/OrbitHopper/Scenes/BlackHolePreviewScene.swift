//
//  BlackHolePreviewScene.swift
//  OrbitHopper
//

import SpriteKit

class BlackHolePreviewScene: SKScene {
    
    let hexColor: String
    
    init(hexColor: String) {
        self.hexColor = hexColor
        super.init(size: CGSize(width: 100, height: 100))
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        self.backgroundColor = .clear
        
        // 1. Create a sprite to render the shader on
        let shaderNode = SKSpriteNode(color: .clear, size: self.size)
        shaderNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // 2. Load the black hole shader and pass the accent color
        let shader = SKShader(fileNamed: "BlackHole.fsh")
        
        if let color = UIColor(hex: hexColor) {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let colorUniform = SKUniform(name: "u_accent_color", vectorFloat3: SIMD3<Float>(Float(r), Float(g), Float(b)))
            shader.uniforms = [colorUniform]
        }
        
        shaderNode.shader = shader
        shaderNode.zPosition = 1
        addChild(shaderNode)
    }
}
