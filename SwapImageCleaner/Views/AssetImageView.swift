import SwiftUI
import AVKit
import Photos

struct AssetImageView: View {
    let asset: PhotoAsset
    let cornerRadius: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var lastRequestedKey: String?
    @State private var shimmerOffset: CGFloat = -1
    @State private var player: AVPlayer?

    private let cache = ImageCache.shared
    private let libraryManager = PhotoLibraryManager.shared

    private var isVideo: Bool {
        asset.mediaType == .video
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                if isVideo, let player {
                    VideoPlayer(player: player)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Loading skeleton
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(white: 0.15),
                                Color(white: 0.18),
                                Color(white: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        if isLoading {
                            // Shimmer effect
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            Color.white.opacity(0.08),
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.08),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset * size.width * 2)
                                .onAppear {
                                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                        shimmerOffset = 1
                                    }
                                }
                        }

                        Image(systemName: "photo")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.15))
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                if isVideo {
                    loadVideo()
                } else {
                    requestImageIfNeeded(for: size, force: true)
                }
            }
            .onChange(of: asset.id) { _ in
                shimmerOffset = -1
                player?.pause()
                player = nil
                if isVideo {
                    loadVideo()
                } else {
                    requestImageIfNeeded(for: size, force: true)
                }
            }
            .onChange(of: size) { newSize in
                if !isVideo {
                    requestImageIfNeeded(for: newSize, force: false)
                }
            }
        }
    }

    private func loadVideo() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestPlayerItem(forVideo: asset.asset, options: options) { playerItem, _ in
            DispatchQueue.main.async {
                if let playerItem {
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    newPlayer.isMuted = false
                    self.player = newPlayer

                    // Loop video
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { _ in
                        newPlayer.seek(to: .zero)
                        newPlayer.play()
                    }
                }
            }
        }
    }

    private func requestImageIfNeeded(for size: CGSize, force: Bool) {
        guard size.width > 40, size.height > 40 else { return }

        let roundedWidth = Int(size.width.rounded())
        let roundedHeight = Int(size.height.rounded())
        let key = "\(asset.id)_\(roundedWidth)x\(roundedHeight)"

        if !force, lastRequestedKey == key {
            return
        }

        if let cached = cache.image(for: key) {
            image = cached
            isLoading = false
            lastRequestedKey = key
            return
        }

        isLoading = true
        lastRequestedKey = key

        libraryManager.requestImage(for: asset, targetSize: size) { uiImage in
            DispatchQueue.main.async {
                if let uiImage {
                    cache.store(uiImage, for: key)
                    image = uiImage
                }
                isLoading = false
            }
        }
    }
}
