//
//  DesignSystem.swift
//  OrbitHopper
//
//  Shared sci-fi design tokens and reusable SwiftUI components
//  matching the HTML mockup aesthetic.
//

import SwiftUI

// MARK: - Design Tokens
struct DS {
    // Neon Colors
    static let green = Color(red: 0/255, green: 255/255, blue: 65/255)
    static let greenDim = Color(red: 0/255, green: 255/255, blue: 65/255).opacity(0.3)
    static let greenGlow = Color(red: 0/255, green: 255/255, blue: 65/255).opacity(0.15)
    
    static let cyan = Color(red: 0/255, green: 232/255, blue: 255/255)
    static let cyanDim = Color(red: 0/255, green: 232/255, blue: 255/255).opacity(0.3)
    
    static let orange = Color(red: 255/255, green: 107/255, blue: 53/255)
    static let orangeDim = Color(red: 255/255, green: 107/255, blue: 53/255).opacity(0.3)
    
    static let red = Color(red: 255/255, green: 51/255, blue: 85/255)
    static let redDim = Color(red: 255/255, green: 51/255, blue: 85/255).opacity(0.3)
    
    static let gold = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let goldDim = Color(red: 255/255, green: 215/255, blue: 0/255).opacity(0.4)
    
    static let spaceBlack = Color(red: 2/255, green: 8/255, blue: 16/255)
    static let panelBg = Color(red: 2/255, green: 10/255, blue: 22/255).opacity(0.92)
    
    // Fonts
    static func orbitron(_ size: CGFloat, weight: String = "Bold") -> Font {
        .custom("Orbitron-\(weight)", size: size)
    }
    
    static func mono(_ size: CGFloat) -> Font {
        .custom("ShareTechMono-Regular", size: size)
    }
}

// MARK: - Sci-Fi Button
struct SciFiButton: View {
    let title: String
    let icon: String?
    let style: ButtonVariant
    let action: () -> Void
    
    enum ButtonVariant {
        case primary    // Green
        case secondary  // Cyan
        case danger     // Orange/Red
        case red        // Red
        case gold       // Gold
    }
    
    init(_ title: String, icon: String? = nil, style: ButtonVariant = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    private var accentColor: Color {
        switch style {
        case .primary: return DS.green
        case .secondary: return DS.cyan
        case .danger: return DS.orange
        case .red: return DS.red
        case .gold: return DS.gold
        }
    }
    
    private var bgOpacity: Double {
        switch style {
        case .primary: return 0.12
        case .secondary: return 0.08
        case .danger: return 0.10
        case .red: return 0.12
        case .gold: return 0.10
        }
    }
    
    private var borderOpacity: Double {
        switch style {
        case .primary: return 0.55
        case .secondary: return 0.45
        case .danger: return 0.45
        case .red: return 0.55
        case .gold: return 0.50
        }
    }
    
    private var height: CGFloat {
        switch style {
        case .primary, .gold: return 52
        default: return 46
        }
    }
    
    private var fontSize: CGFloat {
        switch style {
        case .primary, .gold: return 14
        default: return 12
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: fontSize + 2))
                }
                Text(title)
                    .font(DS.orbitron(fontSize))
                    .tracking(2)
            }
            .foregroundColor(accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(accentColor.opacity(bgOpacity))
            .clipShape(SciFiClipShape())
            .overlay(SciFiClipShape().stroke(accentColor.opacity(borderOpacity), lineWidth: 1))
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Sci-Fi Panel
struct SciFiPanel<Content: View>: View {
    let borderColor: Color
    let content: Content
    
    init(borderColor: Color = DS.green, @ViewBuilder content: () -> Content) {
        self.borderColor = borderColor
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
        }
        .background(DS.panelBg)
        .clipShape(SciFiClipShape())
        .overlay(SciFiClipShape().stroke(borderColor.opacity(0.35), lineWidth: 1))
        .overlay(CornerAccents(color: borderColor))
    }
}

// MARK: - Corner Accents
struct CornerAccents: View {
    let color: Color
    let size: CGFloat
    
    init(color: Color = DS.green, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        GeometryReader { geo in
            // Top-left
            CornerBracket(color: color, size: size)
                .position(x: size/2, y: size/2)
            // Top-right
            CornerBracket(color: color, size: size)
                .rotationEffect(.degrees(90))
                .position(x: geo.size.width - size/2, y: size/2)
            // Bottom-left
            CornerBracket(color: color, size: size)
                .rotationEffect(.degrees(-90))
                .position(x: size/2, y: geo.size.height - size/2)
            // Bottom-right
            CornerBracket(color: color, size: size)
                .rotationEffect(.degrees(180))
                .position(x: geo.size.width - size/2, y: geo.size.height - size/2)
        }
        .allowsHitTesting(false)
    }
}

struct CornerBracket: View {
    let color: Color
    let size: CGFloat
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size, y: 0))
        }
        .stroke(color.opacity(0.75), lineWidth: 2)
        .frame(width: size, height: size)
    }
}

// MARK: - Clip Shape (polygon with clipped corners)
struct SciFiClipShape: Shape {
    let cornerSize: CGFloat
    
    init(cornerSize: CGFloat = 10) {
        self.cornerSize = cornerSize
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = cornerSize
        path.move(to: CGPoint(x: c, y: 0))
        path.addLine(to: CGPoint(x: rect.width - c, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: c))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - c))
        path.addLine(to: CGPoint(x: rect.width - c, y: rect.height))
        path.addLine(to: CGPoint(x: c, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - c))
        path.addLine(to: CGPoint(x: 0, y: c))
        path.closeSubpath()
        return path
    }
}

// MARK: - Scanline Overlay
struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineHeight: CGFloat = 4
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y + 3, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.03)))
                    y += lineHeight
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Vignette Overlay
struct VignetteOverlay: View {
    var color: Color = .black
    
    var body: some View {
        RadialGradient(
            colors: [.clear, color.opacity(0.45)],
            center: .center,
            startRadius: UIScreen.main.bounds.width * 0.35,
            endRadius: UIScreen.main.bounds.width * 0.9
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Space Background
struct SpaceBackground: View {
    var topLeftPlanet: Bool = false
    var topRightPlanet: Bool = false
    var bottomGlow: Color? = nil
    
    var body: some View {
        ZStack {
            // Base space color
            DS.spaceBlack.ignoresSafeArea()
            
            // Nebula gradients
            RadialGradient(
                colors: [Color(red: 0, green: 40/255, blue: 80/255).opacity(0.55), .clear],
                center: UnitPoint(x: 0.2, y: 0.15),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color(red: 0, green: 20/255, blue: 60/255).opacity(0.4), .clear],
                center: UnitPoint(x: 0.8, y: 0.7),
                startRadius: 0,
                endRadius: 250
            )
            .ignoresSafeArea()
            
            // Bottom glow (for main menu)
            if let glow = bottomGlow {
                RadialGradient(
                    colors: [glow.opacity(0.25), .clear],
                    center: UnitPoint(x: 0.5, y: 1.1),
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }
            
            // Stars
            StarsView()
            
            // Decorative planets
            if topLeftPlanet {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 136/255, green: 221/255, blue: 255/255),
                                Color(red: 17/255, green: 119/255, blue: 170/255),
                                Color(red: 0, green: 51/255, blue: 85/255)
                            ],
                            center: UnitPoint(x: 0.4, y: 0.38),
                            startRadius: 0,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)
                    .opacity(0.6)
                    .offset(x: -50, y: -50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            
            if topRightPlanet {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 187/255, green: 153/255, blue: 119/255),
                                Color(red: 119/255, green: 68/255, blue: 51/255),
                                Color(red: 51/255, green: 26/255, blue: 10/255)
                            ],
                            center: UnitPoint(x: 0.38, y: 0.35),
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .opacity(0.5)
                    .offset(x: 30, y: 80)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            
            ScanlineOverlay()
            VignetteOverlay()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Stars View
struct StarsView: View {
    var body: some View {
        Canvas { context, size in
            let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
                (0.10, 0.08, 1), (0.25, 0.18, 1.5), (0.45, 0.05, 1),
                (0.60, 0.22, 2), (0.80, 0.12, 1), (0.90, 0.35, 1),
                (0.15, 0.45, 1.5), (0.35, 0.55, 1), (0.70, 0.48, 1),
                (0.05, 0.70, 2), (0.88, 0.65, 1), (0.50, 0.80, 1),
                (0.20, 0.88, 1.5), (0.75, 0.92, 1), (0.55, 0.38, 0.8),
                (0.30, 0.72, 1.2), (0.95, 0.55, 0.8), (0.42, 0.15, 1),
                (0.65, 0.85, 1.5), (0.12, 0.62, 1),
            ]
            for (x, y, radius) in starPositions {
                let point = CGPoint(x: size.width * x, y: size.height * y)
                let rect = CGRect(x: point.x - radius/2, y: point.y - radius/2, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(Double.random(in: 0.3...0.8))))
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Glow Text Modifier
struct GlowText: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.7), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 2)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowText(color: color, radius: radius))
    }
}

// MARK: - Pulsing Glow Animation
struct PulsingGlow: ViewModifier {
    let color: Color
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 1.0 : 0.5), radius: isGlowing ? 20 : 10)
            .shadow(color: color.opacity(isGlowing ? 0.4 : 0.1), radius: isGlowing ? 40 : 20)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func pulsingGlow(_ color: Color) -> some View {
        modifier(PulsingGlow(color: color))
    }
}

// MARK: - Bouncy Button Style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Color Hex Extension (SwiftUI)
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
