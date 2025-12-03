import SwiftUI
import Photos
import UIKit

struct ContentView: View {
    @ObservedObject var viewModel: PhotoCleanerViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var filterSheetPresented = false
    @State private var optionsExpanded = false

    var body: some View {
        ZStack {
            AuroraBackground()

            switch viewModel.authorizationState {
            case .idle, .requesting:
                LoadingOverlay()
            case .denied:
                AccessDeniedView(openSettings: viewModel.openSettings)
            case .authorized, .limited:
                authorizedLayout
            }
        }
        .onChange(of: scenePhase, perform: viewModel.handleScenePhaseChange)
        .onChange(of: viewModel.authorizationState) { state in
            if !state.isActiveForContent {
                filterSheetPresented = false
                optionsExpanded = false
            }
        }
        .sheet(isPresented: $filterSheetPresented) {
            FilterPanelView(
                albums: viewModel.albums,
                selectedAlbum: viewModel.selectedAlbum,
                dateFilters: viewModel.availableDateFilters,
                selectedDateFilter: viewModel.dateFilter,
                mediaFilters: viewModel.availableMediaFilters,
                selectedMediaFilter: viewModel.mediaFilter,
                onSelectAlbum: { album in
                    filterSheetPresented = false
                    viewModel.selectAlbum(album)
                },
                onSelectDateFilter: { filter in
                    filterSheetPresented = false
                    viewModel.setDateFilter(filter)
                },
                onSelectMediaFilter: { filter in
                    filterSheetPresented = false
                    viewModel.setMediaFilter(filter)
                },
                onRefreshAlbums: viewModel.reloadAlbums
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Bir şey ters gitti", isPresented: viewModel.errorBinding) {
            Button("Tamam", role: .cancel, action: viewModel.clearError)
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen hata")
        }
        .overlay(alignment: .top) {
            if let notice = viewModel.noticeMessage {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: UIApplication.topSafeAreaInset + 12)
                    NoticeBanner(
                        text: notice,
                        onDismiss: viewModel.clearNotice
                    )
                    .padding(.horizontal, 20)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.noticeMessage)
    }

    private var authorizedLayout: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen swipe cards
                SwipeDeckView(
                    currentAsset: viewModel.currentAsset,
                    nextAsset: viewModel.previewAsset,
                    isLoading: viewModel.isLoadingAssets,
                    onKeep: viewModel.keepCurrent,
                    onDelete: viewModel.deleteCurrent,
                    onSkip: viewModel.skipCurrent,
                    onReload: { viewModel.reloadLibrary(resetStats: true) }
                )
                .ignoresSafeArea()

                // Reset button - always visible in top right safe area
                if viewModel.stats.processed > 0 {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { viewModel.resetStats() }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Circle()
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                            }
                            .padding(.top, geometry.safeAreaInsets.top + 12)
                            .padding(.trailing, 16)
                        }
                        Spacer()
                    }
                }

                // Bottom controls - always visible
                VStack {
                    Spacer()

                    ActionDock(
                        stats: viewModel.stats,
                        pendingDeletes: viewModel.pendingDeleteCount,
                        onDelete: viewModel.deleteCurrent,
                        onSkip: viewModel.skipCurrent,
                        onKeep: viewModel.keepCurrent,
                        toggleOptions: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                optionsExpanded.toggle()
                            }
                        },
                        openFilters: { filterSheetPresented = true },
                        randomize: $viewModel.randomizeQueue,
                        includeVideos: $viewModel.includeVideos,
                        showOptions: optionsExpanded
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 12)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Top Overlay

private struct TopOverlayView: View {
    let albumTitle: String
    let dateLabel: String
    let dateHint: String?
    let stats: PhotoCleanerStats
    let pendingDeletes: Int
    let onFilter: () -> Void
    let onReset: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            // Minimal stats only
            HStack(spacing: 4) {
                StatPill(color: .red, icon: "trash.fill", value: stats.deleted, badge: pendingDeletes)
                StatPill(color: .yellow, icon: "arrow.uturn.left", value: stats.skipped, badge: nil)
                StatPill(color: .green, icon: "heart.fill", value: stats.kept, badge: nil)
            }

            Spacer(minLength: 2)

            // Minimal buttons
            Button(action: onFilter) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }

            if let onReset {
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .background(Capsule().fill(Color.black.opacity(0.3)))
        .clipShape(Capsule())
    }
}

private struct StatsCapsule: View {
    let deleted: Int
    let skipped: Int
    let kept: Int
    let pendingDeletes: Int

    var body: some View {
        HStack(spacing: 10) {
            StatPill(color: .red, icon: "trash.fill", value: deleted, badge: pendingDeletes)
            StatPill(color: .yellow, icon: "arrow.uturn.left", value: skipped, badge: nil)
            StatPill(color: .green, icon: "heart.fill", value: kept, badge: nil)
        }
    }
}

private struct StatPill: View {
    let color: Color
    let icon: String
    let value: Int
    let badge: Int?

    @State private var previousValue: Int = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(Color.white.opacity(0.12)))
            )
            .scaleEffect(scale)

            if let badge, badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 8, weight: .heavy))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color.opacity(0.9)))
                    .foregroundStyle(.white)
                    .offset(x: 3, y: -3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: value) { newValue in
            if newValue != previousValue {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                    scale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                        scale = 1.0
                    }
                }
                previousValue = newValue
            }
        }
        .onAppear {
            previousValue = value
        }
    }
}

// MARK: - Bottom Dock

private struct ActionDock: View {
    let stats: PhotoCleanerStats
    let pendingDeletes: Int
    let onDelete: () -> Void
    let onSkip: () -> Void
    let onKeep: () -> Void
    let toggleOptions: () -> Void
    let openFilters: () -> Void
    @Binding var randomize: Bool
    @Binding var includeVideos: Bool
    let showOptions: Bool

    var body: some View {
        VStack(spacing: 8) {
            if showOptions {
                HStack(spacing: 6) {
                    OptionToggleButton(
                        isOn: $randomize,
                        icon: "shuffle",
                        title: "Rastgele"
                    )
                    OptionToggleButton(
                        isOn: $includeVideos,
                        icon: "video.fill",
                        title: "Video"
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 8) {
                ActionButton(style: .delete, action: onDelete, badge: stats.deleted, pendingBadge: pendingDeletes)
                ActionButton(style: .skip, action: onSkip, badge: stats.skipped, pendingBadge: nil)
                ActionButton(style: .keep, action: onKeep, badge: stats.kept, pendingBadge: nil)

                Button(action: openFilters) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: toggleOptions) {
                    Image(systemName: showOptions ? "xmark" : "ellipsis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.ultraThinMaterial)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.25))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

private struct OptionToggleButton: View {
    @Binding var isOn: Bool
    let icon: String
    let title: String

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.caption2.weight(.bold))
                ZStack {
                    Capsule()
                        .fill(isOn ? Color.green.opacity(0.8) : Color.white.opacity(0.2))
                        .frame(width: 32, height: 16)
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .offset(x: isOn ? 8 : -8)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(.white)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ActionButton: View {
    enum Style {
        case delete, skip, keep

        var colors: [Color] {
            switch self {
            case .delete:
                return [Color(red: 0.98, green: 0.39, blue: 0.45), Color(red: 0.85, green: 0.18, blue: 0.38)]
            case .skip:
                return [Color(red: 1.0, green: 0.78, blue: 0.42), Color(red: 0.96, green: 0.62, blue: 0.28)]
            case .keep:
                return [Color(red: 0.32, green: 0.87, blue: 0.65), Color(red: 0.22, green: 0.72, blue: 0.55)]
            }
        }

        var icon: String {
            switch self {
            case .delete:
                return "trash.fill"
            case .skip:
                return "arrow.uturn.left"
            case .keep:
                return "heart.fill"
            }
        }

        var badgeColor: Color {
            switch self {
            case .delete:
                return .red
            case .skip:
                return .yellow
            case .keep:
                return .green
            }
        }
        
        var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .delete:
                return .heavy
            case .skip:
                return .light
            case .keep:
                return .medium
            }
        }
    }

    let style: Style
    let action: () -> Void
    let badge: Int
    let pendingBadge: Int?

    @State private var isPressed = false
    @State private var glowIntensity: CGFloat = 0

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: style.hapticStyle)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
                glowIntensity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isPressed = false
                    glowIntensity = 0
                }
            }

            action()
        }) {
            ZStack(alignment: .topTrailing) {
                // Glow effect on press
                Circle()
                    .fill(style.colors.first?.opacity(0.4) ?? .clear)
                    .frame(width: 56, height: 56)
                    .blur(radius: 10)
                    .scaleEffect(isPressed ? 1.3 : 0.8)
                    .opacity(glowIntensity)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: style.colors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: style.icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(isPressed ? 0.85 : 1)
                    )
                    .shadow(color: style.colors.last?.opacity(isPressed ? 0.6 : 0.4) ?? .black.opacity(0.3), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 2 : 4)
                    .scaleEffect(isPressed ? 0.88 : 1)

                // Badge
                let actualDeleted = badge - (pendingBadge ?? 0)
                if actualDeleted > 0 || (pendingBadge ?? 0) > 0 {
                    VStack(spacing: 2) {
                        // Main badge (actual confirmed deletes)
                        if actualDeleted > 0 {
                            Text("\(actualDeleted)")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(style.badgeColor.opacity(0.95)))
                                .shadow(color: style.badgeColor.opacity(0.5), radius: 4, x: 0, y: 2)
                        }

                        // Pending badge (waiting to be deleted)
                        if let pendingBadge, pendingBadge > 0 {
                            Text("\(pendingBadge)")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.95)))
                                .shadow(color: Color.orange.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                    }
                    .offset(x: 6, y: -6)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: badge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        switch style {
        case .delete:
            return "Sil, \(badge) silindi"
        case .skip:
            return "Atla, \(badge) atlandı"
        case .keep:
            return "Tut, \(badge) tutuldu"
        }
    }
    
    private var accessibilityHint: String {
        switch style {
        case .delete:
            return "Bu fotoğrafı silmek için çift dokunun"
        case .skip:
            return "Bu fotoğrafı atlamak için çift dokunun"
        case .keep:
            return "Bu fotoğrafı tutmak için çift dokunun"
        }
    }
}

// MARK: - Filter Panel

private struct FilterPanelView: View {
    let albums: [PhotoAlbum]
    let selectedAlbum: PhotoAlbum
    let dateFilters: [DateFilter]
    let selectedDateFilter: DateFilter
    let mediaFilters: [MediaFilter]
    let selectedMediaFilter: MediaFilter
    let onSelectAlbum: (PhotoAlbum) -> Void
    let onSelectDateFilter: (DateFilter) -> Void
    let onSelectMediaFilter: (MediaFilter) -> Void
    let onRefreshAlbums: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SectionHeader(title: "Albüm seç")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(albums) { album in
                            AlbumChip(
                                album: album,
                                isSelected: album.id == selectedAlbum.id,
                                action: {
                                    onSelectAlbum(album)
                                    dismiss()
                                }
                            )
                        }
                    }

                    Button("Albümleri yenile", action: onRefreshAlbums)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15), in: Capsule())

                    Divider().padding(.vertical, 4)

                    SectionHeader(title: "Medya tipi")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(mediaFilters) { filter in
                            MediaFilterRow(
                                filter: filter,
                                isSelected: filter == selectedMediaFilter,
                                action: {
                                    onSelectMediaFilter(filter)
                                    dismiss()
                                }
                            )
                        }
                    }

                    Divider().padding(.vertical, 4)

                    SectionHeader(title: "Zaman filtresi")
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(dateFilters) { filter in
                            DateFilterRow(
                                filter: filter,
                                isSelected: filter == selectedDateFilter,
                                action: {
                                    onSelectDateFilter(filter)
                                    dismiss()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Filtreler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

private struct AlbumChip: View {
    let album: PhotoAlbum
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(album.title)
                    .font(.subheadline.weight(.semibold))
                if !album.displaySubtitle.isEmpty {
                    Text(album.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MediaFilterRow: View {
    let filter: MediaFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(filter.title)
                        .font(.body.weight(.semibold))
                    if let subtitle = filter.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(isSelected ? 0.15 : 0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DateFilterRow: View {
    let filter: DateFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(filter.title)
                        .font(.body.weight(.semibold))
                    if let subtitle = filter.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(isSelected ? 0.15 : 0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - State Views

private struct LoadingOverlay: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple, Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

                Image(systemName: "photo.stack")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                Text("Fotoğraflar hazırlanıyor")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
                Text("Lütfen bekleyin...")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 36)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.2))
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
        .onAppear {
            isAnimating = true
        }
    }
}

private struct NoticeBanner: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

private extension UIApplication {
    static var topSafeAreaInset: CGFloat {
        guard
            let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        else { return 0 }
        return window.safeAreaInsets.top
    }
}

private struct AccessDeniedView: View {
    let openSettings: () -> Void
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)
                    .opacity(isPulsing ? 0.8 : 0.5)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)

                Image(systemName: "lock.slash.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Fotoğraflara erişim izni gerekli")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text("Fotoğrafları temizlemek için galeri erişimini etkinleştir. Sağa kaydırarak silin, sola kaydırarak tutun.")
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 8)
            }

            Button(action: openSettings) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.headline.weight(.bold))
                    Text("Ayarları Aç")
                        .font(.callout.weight(.bold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.white)
                )
                .foregroundColor(.black)
                .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 42)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.2))
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 12)
        .onAppear {
            isPulsing = true
        }
    }
}

private extension PhotoCleanerViewModel.AuthorizationState {
    var isActiveForContent: Bool {
        switch self {
        case .authorized, .limited:
            return true
        case .idle, .requesting, .denied:
            return false
        }
    }
}
