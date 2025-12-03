import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var iconScale: CGFloat = 0.7
    @State private var iconOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        if isActive {
            AppRootView()
        } else {
            ZStack {
                // Background matching aurora
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.06, blue: 0.12),
                        Color(red: 0.08, green: 0.06, blue: 0.14),
                        Color(red: 0.04, green: 0.04, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // App Icon
                    AppIconView(size: 120)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                    
                    // App Name
                    VStack(spacing: 6) {
                        Text("Galeri Temizleyici")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        
                        Text("Kaydır ve Temizle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                }
            }
            .onAppear {
                // Icon animation
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
                
                // Text animation
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    textOpacity = 1.0
                    textOffset = 0
                }
                
                // Transition to main app
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

// AppIconView for splash (reusing from OnboardingView)
private struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        Group {
            if let icon = loadAppIcon() {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Fallback gradient icon
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "photo.stack")
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .shadow(color: Color.purple.opacity(0.4), radius: 20, x: 0, y: 10)
    }
    
    private func loadAppIcon() -> UIImage? {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        
        let iconNames = ["AppIcon60x60", "AppIcon", "Icon-60@3x", "icon-60@3x"]
        for name in iconNames {
            if let icon = UIImage(named: name) {
                return icon
            }
        }
        
        return nil
    }
}

#Preview {
    SplashView()
}
