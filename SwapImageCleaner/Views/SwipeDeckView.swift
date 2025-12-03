import SwiftUI

struct SwipeDeckView: View {
    let currentAsset: PhotoAsset?
    let nextAsset: PhotoAsset?
    let isLoading: Bool
    let onKeep: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void
    let onReload: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let availableHeight = proxy.size.height
            let imageAspect: CGFloat = 3.0 / 4.0
            let screenAspect = availableWidth / availableHeight

            let cardDimensions = calculateCardSize(
                availableWidth: availableWidth,
                availableHeight: availableHeight,
                imageAspect: imageAspect,
                screenAspect: screenAspect
            )

            ZStack {
                if let nextAsset {
                    AssetCardView(
                        asset: nextAsset,
                        cornerRadius: 20,
                        shadowOpacity: 0.15,
                        isPreview: true
                    )
                    .frame(width: cardDimensions.width * 0.96, height: cardDimensions.height * 0.96)
                    .scaleEffect(0.95)
                    .offset(y: 16)
                    .opacity(0.6)
                    .allowsHitTesting(false)
                }

                if let currentAsset {
                    SwipeCardView(
                        asset: currentAsset,
                        containerSize: cardDimensions,
                        onKeep: onKeep,
                        onDelete: onDelete,
                        onSkip: onSkip
                    )
                    .frame(width: cardDimensions.width, height: cardDimensions.height)
                } else if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.2)
                        Text("Fotoğraflar taranıyor…")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                } else {
                    EmptyDeckView(refreshAction: onReload)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func calculateCardSize(availableWidth: CGFloat, availableHeight: CGFloat, imageAspect: CGFloat, screenAspect: CGFloat) -> CGSize {
        if screenAspect > imageAspect {
            // Screen is wider - fit to height
            let height = availableHeight
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        } else {
            // Screen is taller - fit to width
            let width = availableWidth
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        }
    }
}

private struct EmptyDeckView: View {
    let refreshAction: () -> Void
    
    @State private var sparkleRotation: Double = 0
    @State private var sparkleScale: CGFloat = 1.0
    @State private var appearScale: CGFloat = 0.8
    @State private var appearOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            // Animated icon
            ZStack {
                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 70, height: 70)
                    .scaleEffect(sparkleScale)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(sparkleRotation))
                    )
                    .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 4)
            }

            // Minimal text
            VStack(spacing: 4) {
                Text("Galerin tertemiz!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Yeniden taramak için butona bas.")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Small button with animation
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                refreshAction()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                    Text("Yeniden tara")
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(.white))
                .foregroundColor(.black)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.3))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                sparkleRotation = 15
                sparkleScale = 1.1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Galerin tertemiz")
        .accessibilityHint("Yeniden taramak için çift dokunun")
    }
}
