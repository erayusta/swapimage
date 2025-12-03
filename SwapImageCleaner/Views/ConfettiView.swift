import SwiftUI

/// A celebratory confetti animation view
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [
        .purple, .blue, .pink, .orange, .green, .yellow, .cyan, .mint
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                isAnimating = true
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                targetY: size.height + 50,
                color: colors.randomElement() ?? .purple,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    
    @State private var currentY: CGFloat = -20
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1
    @State private var horizontalOffset: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .rotationEffect(.degrees(currentRotation))
            .position(x: particle.x + horizontalOffset, y: currentY)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.5)
                    .delay(particle.delay)
                ) {
                    currentY = particle.targetY
                    opacity = 0
                }
                
                withAnimation(
                    .linear(duration: 2.5)
                    .delay(particle.delay)
                ) {
                    currentRotation = particle.rotation + Double.random(in: 360...720)
                }
                
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatCount(5, autoreverses: true)
                    .delay(particle.delay)
                ) {
                    horizontalOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}

/// Success checkmark animation
struct SuccessCheckmark: View {
    @State private var scale: CGFloat = 0
    @State private var opacity: CGFloat = 0
    @State private var checkmarkProgress: CGFloat = 0
    
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
                .scaleEffect(scale)
            
            // Checkmark
            CheckmarkShape()
                .trim(from: 0, to: checkmarkProgress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1
                opacity = 1
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                checkmarkProgress = 1
            }
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.15, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.25))
        
        return path
    }
}

/// Animated swipe gesture hint
struct SwipeHintView: View {
    let direction: SwipeDirection
    @State private var offset: CGFloat = 0
    @State private var opacity: CGFloat = 0.6
    
    enum SwipeDirection {
        case left, right, up
        
        var icon: String {
            switch self {
            case .left: return "arrow.left"
            case .right: return "arrow.right"
            case .up: return "arrow.up"
            }
        }
        
        var color: Color {
            switch self {
            case .left: return .red
            case .right: return .green
            case .up: return .orange
            }
        }
    }
    
    var body: some View {
        Image(systemName: direction.icon)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(direction.color)
            .offset(
                x: direction == .left ? -offset : (direction == .right ? offset : 0),
                y: direction == .up ? -offset : 0
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 10
                    opacity = 1
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}
