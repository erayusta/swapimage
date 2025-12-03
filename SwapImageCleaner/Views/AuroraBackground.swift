import SwiftUI

struct AuroraBackground: View {
    var isDimmed: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
            AuroraCanvas(time: timeline.date.timeIntervalSinceReferenceDate, isDimmed: isDimmed)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

private struct AuroraCanvas: View {
    let time: TimeInterval
    let isDimmed: Bool
    
    var body: some View {
        ZStack {
            baseGradient
            purpleGradient
            pinkGradient
            cyanOrb
            floatingParticles
        }
    }
    
    private var baseGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.18),
                Color(red: 0.10, green: 0.07, blue: 0.15),
                Color(red: 0.02, green: 0.04, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var purpleGradient: some View {
        let purpleOpacity = isDimmed ? 0.18 : 0.25
        let blueOpacity = isDimmed ? 0.1 : 0.15
        let centerX = 0.7 + sin(time * 0.3) * 0.1
        let centerY = 0.2 + cos(time * 0.25) * 0.08
        let endRadius = 380.0 + sin(time * 0.4) * 20.0
        
        return RadialGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(purpleOpacity),
                Color.blue.opacity(blueOpacity),
                .clear
            ]),
            center: UnitPoint(x: centerX, y: centerY),
            startRadius: 20,
            endRadius: endRadius
        )
        .blendMode(.screen)
    }
    
    private var pinkGradient: some View {
        let pinkOpacity = isDimmed ? 0.12 : 0.18
        let orangeOpacity = isDimmed ? 0.05 : 0.08
        let centerX = 0.3 + cos(time * 0.35) * 0.12
        let centerY = 0.8 + sin(time * 0.28) * 0.1
        let endRadius = 400.0 + cos(time * 0.5) * 25.0
        
        return RadialGradient(
            gradient: Gradient(colors: [
                Color.pink.opacity(pinkOpacity),
                Color.orange.opacity(orangeOpacity),
                .clear
            ]),
            center: UnitPoint(x: centerX, y: centerY),
            startRadius: 30,
            endRadius: endRadius
        )
        .blendMode(.screen)
    }
    
    private var cyanOrb: some View {
        let cyanOpacity = isDimmed ? 0.08 : 0.12
        let offsetX = 100.0 + sin(time * 0.2) * 30.0
        let offsetY = -150.0 + cos(time * 0.18) * 25.0
        
        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(cyanOpacity),
                        .clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 250
                )
            )
            .frame(width: 500, height: 500)
            .offset(x: offsetX, y: offsetY)
            .blur(radius: 60)
            .blendMode(.plusLighter)
    }
    
    private var floatingParticles: some View {
        let whiteOpacity = isDimmed ? 0.02 : 0.04
        
        return ForEach(0..<3, id: \.self) { index in
            let indexDouble = Double(index)
            let offsetX = sin(time * (0.15 + indexDouble * 0.05)) * 120.0 - 50.0 + indexDouble * 80.0
            let offsetY = cos(time * (0.12 + indexDouble * 0.04)) * 100.0 + indexDouble * 150.0 - 200.0
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(whiteOpacity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 150, height: 150)
                .offset(x: offsetX, y: offsetY)
                .blur(radius: 40)
                .blendMode(.plusLighter)
        }
    }
}
