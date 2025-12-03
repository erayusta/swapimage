import SwiftUI

struct OnboardingView: View {
    struct Slide: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let accent: [Color]
        let highlights: [String]
    }

    private let slides: [Slide] = [
        .init(
            title: "Galerini hafiflet",
            description: "Sağa kaydırıp tut, sola kaydırıp sil. Tek dokunuşla gereksiz fotoğraflardan kurtul.",
            icon: "hand.draw",
            accent: [Color(red: 0.82, green: 0.39, blue: 1.0), Color(red: 0.35, green: 0.67, blue: 1.0)],
            highlights: ["Hızlı kaydır", "Anında karar"]
        ),
        .init(
            title: "Akıllı filtreler",
            description: "Albüm, tarih ve medya tipine göre filtrele. Önce önemli olanlara odaklan.",
            icon: "slider.horizontal.3",
            accent: [Color(red: 0.99, green: 0.64, blue: 0.48), Color(red: 1.0, green: 0.84, blue: 0.42)],
            highlights: ["Tarih aralığı", "Albüm seç"]
        ),
        .init(
            title: "Mahremiyet seninle",
            description: "Hiçbir görsel cihazından çıkmaz. Tam kontrol için Fotoğraflar iznini açman yeter.",
            icon: "lock.shield",
            accent: [Color(red: 0.37, green: 0.91, blue: 0.76), Color(red: 0.25, green: 0.63, blue: 0.96)],
            highlights: ["Yerel işlem", "Apple güvenliği"]
        )
    ]

    let onFinish: () -> Void

    @State private var currentIndex = 0
    @State private var headerOpacity: CGFloat = 0
    @State private var headerOffset: CGFloat = -20
    @State private var buttonScale: CGFloat = 0.9
    @State private var showConfetti = false
    
    private let hapticSelection = UISelectionFeedbackGenerator()
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        GeometryReader { proxy in
            let safeInsets = proxy.safeAreaInsets
            let usableHeight = proxy.size.height - safeInsets.top - safeInsets.bottom
            let isCompact = usableHeight < 700 || proxy.size.width < 360
            let cardHeight = min(max(usableHeight * 0.55, 280), isCompact ? 360 : 500)

            ZStack {
                AuroraBackground(isDimmed: true)

                VStack(spacing: isCompact ? 16 : 24) {
                    header(isCompact: isCompact)
                        .opacity(headerOpacity)
                        .offset(y: headerOffset)

                    TabView(selection: $currentIndex) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                            SlideView(slide: slide, isCompact: isCompact)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight)
                    .onChange(of: currentIndex) { _ in
                        hapticSelection.selectionChanged()
                    }

                    VStack(spacing: isCompact ? 12 : 16) {
                        PageIndicator(count: slides.count, index: currentIndex, isCompact: isCompact)

                        Button(action: advance) {
                            Text(currentIndex == slides.count - 1 ? "Başlayalım" : "Devam")
                                .font((isCompact ? Font.body : Font.headline).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, isCompact ? 12 : 16)
                                .background(
                                    LinearGradient(
                                        colors: slides[currentIndex].accent,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: slides[currentIndex].accent.last?.opacity(0.4) ?? .black.opacity(0.25), radius: 12, x: 0, y: 8)
                        }
                        .scaleEffect(buttonScale)
                    }
                }
                .padding(.horizontal, isCompact ? 16 : 24)
                .padding(.top, safeInsets.top + (isCompact ? 8 : 28))
                .padding(.bottom, safeInsets.bottom + (isCompact ? 12 : 32))
                
                // Confetti overlay for final slide
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                hapticSelection.prepare()
                hapticImpact.prepare()
                
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    headerOpacity = 1
                    headerOffset = 0
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                    buttonScale = 1.0
                }
            }
        }
    }

    private func header(isCompact: Bool) -> some View {
        HStack(spacing: 12) {
            // App Icon
            AppIconView(size: isCompact ? 44 : 52)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Hadi başlayalım")
                    .font((isCompact ? Font.title3 : Font.title2).weight(.bold))
                    .foregroundStyle(.white)
                Text("Galerini temizlemeye hazır mısın?")
                    .font((isCompact ? Font.caption : Font.footnote).weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: onFinish) {
                Text("Atla")
                    .font((isCompact ? Font.caption : Font.subheadline).weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, isCompact ? 14 : 16)
                    .padding(.vertical, isCompact ? 8 : 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func advance() {
        hapticImpact.impactOccurred(intensity: 0.7)
        
        if currentIndex < slides.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentIndex += 1
            }
            
            // Show confetti on last slide
            if currentIndex == slides.count - 1 {
                showConfetti = true
            }
        } else {
            let successHaptic = UINotificationFeedbackGenerator()
            successHaptic.notificationOccurred(.success)
            onFinish()
        }
    }
}

private struct SlideView: View {
    let slide: OnboardingView.Slide
    let isCompact: Bool
    
    @State private var iconPulse: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.4

    var body: some View {
        let circleSize: CGFloat = isCompact ? 110 : 140
        let iconSize: CGFloat = isCompact ? 44 : 54
        let contentPadding: CGFloat = isCompact ? 18 : 28

        VStack(spacing: isCompact ? 18 : 24) {
            ZStack {
                // Animated glow background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: slide.accent.map { $0.opacity(glowOpacity) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: circleSize * iconPulse, height: circleSize * iconPulse)
                    .blur(radius: 15)
                
                // Secondary glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: slide.accent.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: circleSize * 0.85, height: circleSize * 0.85)
                    .scaleEffect(iconPulse)
                    .opacity(2 - iconPulse)
                
                Image(systemName: slide.icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: slide.accent,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: slide.accent.last?.opacity(0.6) ?? .black.opacity(0.4), radius: 15, x: 0, y: 8)
                    .scaleEffect(iconPulse * 0.95 + 0.05)
            }
            .padding(.top, isCompact ? 12 : 20)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    iconPulse = 1.08
                    glowOpacity = 0.55
                }
            }

            VStack(spacing: isCompact ? 8 : 12) {
                Text(slide.title)
                    .font((isCompact ? Font.title3 : Font.title2).weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text(slide.description)
                    .font((isCompact ? Font.callout : Font.body).weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
            }

            ViewThatFits {
                HStack(spacing: 10) {
                    highlightPills
                }
                VStack(spacing: 8) {
                    highlightPills
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, contentPadding)
        .padding(.bottom, isCompact ? 24 : 40)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var highlightPills: some View {
        ForEach(slide.highlights, id: \.self) { highlight in
            Text(highlight)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
        }
    }
}

private struct PageIndicator: View {
    let count: Int
    let index: Int
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 4 : 6) {
            ForEach(0..<count, id: \.self) { item in
                Capsule()
                    .fill(item == index ? Color.white : Color.white.opacity(0.25))
                    .frame(width: item == index ? (isCompact ? 18 : 24) : 8, height: isCompact ? 5 : 6)
                    .animation(.easeInOut(duration: 0.25), value: index)
            }
        }
    }
}

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
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func loadAppIcon() -> UIImage? {
        // Try to load from bundle
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        
        // Fallback: try common names
        let iconNames = ["AppIcon60x60", "AppIcon", "Icon-60@3x", "icon-60@3x"]
        for name in iconNames {
            if let icon = UIImage(named: name) {
                return icon
            }
        }
        
        return nil
    }
}
