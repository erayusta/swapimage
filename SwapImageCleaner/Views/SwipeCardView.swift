import SwiftUI

struct SwipeCardView: View {
    enum SwipeOutcome {
        case keep
        case delete
        case skip
    }

    let asset: PhotoAsset
    let containerSize: CGSize
    let onKeep: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void

    @State private var translation: CGSize = .zero
    @State private var swipeOutcome: SwipeOutcome?
    @State private var isAnimatingOut = false
    @State private var shimmerOffset: CGFloat = -1
    @State private var cardAppearScale: CGFloat = 0.92
    @State private var cardAppearOpacity: CGFloat = 0
    @State private var lastHapticThreshold: Int = 0

    private let threshold: CGFloat = 120
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        AssetCardView(asset: asset, cornerRadius: 28, shadowOpacity: 0.3, isPreview: false)
            .offset(translation)
            .rotationEffect(.degrees(Double(translation.width / 20)))
            .scaleEffect(isAnimatingOut ? 0.95 : cardAppearScale)
            .opacity(cardAppearOpacity)
            .overlay {
                // Shimmer effect
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.15),
                                .white.opacity(0.25),
                                .white.opacity(0.15),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset * containerSize.width * 2)
                    .mask(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                    )
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                overlayLabel(for: translation.width)
                    .padding(.leading, 60)
                    .padding(.top, 80)
            }
            .overlay(alignment: .topTrailing) {
                overlayLabel(for: translation.width, isTrailing: true)
                    .padding(.trailing, 60)
                    .padding(.top, 80)
            }
            .overlay(alignment: .bottom) {
                if translation.height < -threshold {
                    let skipProgress = min(abs(translation.height) / threshold, 1.0)
                    let skipIntensity = pow(skipProgress, 0.7)

                    ZStack {
                        // Animated gradient background
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.8, blue: 0.4),
                                        Color(red: 0.95, green: 0.7, blue: 0.5),
                                        Color(red: 1.0, green: 0.8, blue: 0.4)
                                    ],
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                )
                            )
                            .frame(width: 100 * skipIntensity, height: 100 * skipIntensity)
                            .blur(radius: 35)
                            .opacity(skipIntensity * 0.5)

                        // Icon with glow
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 1.0, green: 0.95, blue: 0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.7), radius: 18, x: 0, y: 0)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.3), radius: 28, x: 0, y: 0)
                    }
                    .scaleEffect(0.7 + (skipIntensity * 0.4))
                    .opacity(0.5 + (skipIntensity * 0.5))
                    .padding(.bottom, 50)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: skipIntensity)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .local)
                    .onChanged { value in
                        guard !isAnimatingOut else { return }
                        translation = value.translation
                        provideProgressiveHaptic(for: value.translation)
                    }
                    .onEnded { value in
                        guard !isAnimatingOut else { return }
                        handleDragEnded(value: value)
                    }
            )
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: translation)
            .onAppear {
                // Prepare haptics
                hapticLight.prepare()
                hapticMedium.prepare()
                hapticHeavy.prepare()
                
                // Card entrance animation
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    cardAppearScale = 1.0
                    cardAppearOpacity = 1.0
                }
                
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1
                }
            }
            .onChange(of: asset.id) { _ in
                // Reset and animate for new card
                cardAppearScale = 0.92
                cardAppearOpacity = 0
                lastHapticThreshold = 0
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                    cardAppearScale = 1.0
                    cardAppearOpacity = 1.0
                }
            }
    }
    
    private func provideProgressiveHaptic(for translation: CGSize) {
        let horizontalProgress = abs(translation.width) / threshold
        let verticalProgress = -translation.height / threshold
        let maxProgress = max(horizontalProgress, verticalProgress)
        
        let currentThreshold = Int(maxProgress * 3) // 0, 1, 2, 3 stages
        
        if currentThreshold > lastHapticThreshold && currentThreshold <= 3 {
            switch currentThreshold {
            case 1:
                hapticLight.impactOccurred(intensity: 0.5)
            case 2:
                hapticMedium.impactOccurred(intensity: 0.7)
            case 3:
                hapticHeavy.impactOccurred(intensity: 1.0)
            default:
                break
            }
            lastHapticThreshold = currentThreshold
        } else if currentThreshold < lastHapticThreshold {
            lastHapticThreshold = currentThreshold
        }
    }

    private func handleDragEnded(value: DragGesture.Value) {
        let predicted = value.predictedEndTranslation
        let horizontal = translation.width + predicted.width * 0.2
        let vertical = translation.height + predicted.height * 0.2

        if horizontal > threshold {
            performSwipe(.keep)
        } else if horizontal < -threshold {
            performSwipe(.delete)
        } else if vertical < -threshold {
            performSwipe(.skip)
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                translation = .zero
                swipeOutcome = nil
            }
        }
    }

    private func performSwipe(_ outcome: SwipeOutcome) {
        swipeOutcome = outcome
        isAnimatingOut = true
        
        // Success haptic on confirmed swipe
        let notificationGenerator = UINotificationFeedbackGenerator()
        switch outcome {
        case .keep:
            notificationGenerator.notificationOccurred(.success)
        case .delete:
            notificationGenerator.notificationOccurred(.warning)
        case .skip:
            hapticMedium.impactOccurred(intensity: 0.6)
        }

        let targetOffset: CGSize
        switch outcome {
        case .keep:
            targetOffset = CGSize(width: containerSize.width * 1.2, height: translation.height / 3)
        case .delete:
            targetOffset = CGSize(width: -containerSize.width * 1.2, height: translation.height / 3)
        case .skip:
            targetOffset = CGSize(width: translation.width / 3, height: -containerSize.height * 1.2)
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            translation = targetOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            switch outcome {
            case .keep:
                onKeep()
            case .delete:
                onDelete()
            case .skip:
                onSkip()
            }
            translation = .zero
            isAnimatingOut = false
            swipeOutcome = nil
        }
    }

    @ViewBuilder
    private func overlayLabel(for horizontalOffset: CGFloat, isTrailing: Bool = false) -> some View {
        let keepActive = horizontalOffset > threshold / 2
        let deleteActive = horizontalOffset < -threshold / 2
        let progress = min(abs(horizontalOffset) / threshold, 1.0)
        let intensity = pow(progress, 0.7) // Smooth easing

        if isTrailing {
            if keepActive {
                ZStack {
                    // Animated gradient background
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.95, blue: 0.7),
                                    Color(red: 0.4, green: 0.85, blue: 0.9),
                                    Color(red: 0.3, green: 0.95, blue: 0.7)
                                ],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            )
                        )
                        .frame(width: 120 * intensity, height: 120 * intensity)
                        .blur(radius: 40)
                        .opacity(intensity * 0.6)

                    // Icon with glow
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.9, green: 1.0, blue: 0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 0.3, green: 0.95, blue: 0.7).opacity(0.8), radius: 20, x: 0, y: 0)
                            .shadow(color: Color(red: 0.3, green: 0.95, blue: 0.7).opacity(0.4), radius: 30, x: 0, y: 0)
                    }
                }
                .scaleEffect(0.7 + (intensity * 0.5))
                .opacity(0.5 + (intensity * 0.5))
                .rotationEffect(.degrees(-15 * intensity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: intensity)
            }
        } else {
            if deleteActive {
                ZStack {
                    // Animated gradient background
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.5),
                                    Color(red: 0.95, green: 0.4, blue: 0.3),
                                    Color(red: 1.0, green: 0.3, blue: 0.5)
                                ],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            )
                        )
                        .frame(width: 120 * intensity, height: 120 * intensity)
                        .blur(radius: 40)
                        .opacity(intensity * 0.6)

                    // Icon with glow
                    ZStack {
                        Image(systemName: "xmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 1.0, green: 0.9, blue: 0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.8), radius: 20, x: 0, y: 0)
                            .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.4), radius: 30, x: 0, y: 0)
                    }
                }
                .scaleEffect(0.7 + (intensity * 0.5))
                .opacity(0.5 + (intensity * 0.5))
                .rotationEffect(.degrees(15 * intensity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: intensity)
            }
        }
    }
}

struct AssetCardView: View {
    let asset: PhotoAsset
    let cornerRadius: CGFloat
    let shadowOpacity: Double
    let isPreview: Bool

    var body: some View {
        AssetImageView(asset: asset, cornerRadius: cornerRadius)
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: isPreview ? 16 : 28,
                x: 0,
                y: isPreview ? 10 : 20
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPreview ? 0.15 : 0.25),
                                Color.white.opacity(isPreview ? 0.05 : 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isPreview ? 1 : 1.5
                    )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(asset.mediaType == .video ? "Video" : "Fotoğraf")
            .accessibilityHint(isPreview ? "Sıradaki içerik" : "Sağa kaydırarak tut, sola kaydırarak sil, yukarı kaydırarak atla")
    }
}
