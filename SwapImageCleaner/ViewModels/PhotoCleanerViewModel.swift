import Foundation
import Photos
import SwiftUI

struct PhotoCleanerStats {
    var kept: Int = 0
    var deleted: Int = 0
    var skipped: Int = 0

    var processed: Int {
        kept + deleted + skipped
    }
}

@MainActor
final class PhotoCleanerViewModel: ObservableObject {
    enum AuthorizationState {
        case idle
        case requesting
        case authorized
        case limited
        case denied

        var isAuthorized: Bool {
            switch self {
            case .authorized, .limited:
                return true
            case .idle, .requesting, .denied:
                return false
            }
        }
    }

    private enum FlushReason {
        case threshold
        case force
    }

    // Published state
    @Published private(set) var authorizationState: AuthorizationState = .idle
    @Published private(set) var currentAsset: PhotoAsset?
    @Published private(set) var previewAsset: PhotoAsset?
    @Published private(set) var isLoadingAssets: Bool = false
    @Published var includeVideos: Bool = false {
        didSet {
            guard includeVideos != oldValue else { return }
            Task { await reloadAssets(resetStats: false) }
        }
    }
    @Published var randomizeQueue: Bool = false {
        didSet {
            guard randomizeQueue != oldValue else { return }
            Task { await reloadAssets(resetStats: false) }
        }
    }
    @Published var stats = PhotoCleanerStats()
    @Published private(set) var albums: [PhotoAlbum] = [.allPhotos]
    @Published private(set) var selectedAlbum: PhotoAlbum = .allPhotos
    @Published private(set) var dateFilter: DateFilter = .all
    @Published private(set) var mediaFilter: MediaFilter = .all
    @Published private(set) var pendingDeleteCount: Int = 0
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    var availableDateFilters: [DateFilter] {
        DateFilter.allCases
    }

    var availableMediaFilters: [MediaFilter] {
        MediaFilter.allCases
    }

    var albumDisplayName: String {
        selectedAlbum.title
    }

    var dateFilterDisplayName: String {
        dateFilter.title
    }

    var dateFilterHint: String? {
        dateFilter.subtitle
    }

    var mediaFilterDisplayName: String {
        mediaFilter.title
    }

    var mediaFilterHint: String? {
        mediaFilter.subtitle
    }

    var errorBinding: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { newValue in
                if newValue == false {
                    self.errorMessage = nil
                }
            }
        )
    }

    // Internal state
    private var assetQueue: [PhotoAsset] = []
    private var pendingDeleteQueue: [PhotoAsset] = []
    private var pendingDeleteIdentifiers = Set<String>()
    private var pendingDeleteStatsCount: Int = 0
    private var deleteWorkItem: DispatchWorkItem?
    private var didBootstrap = false
    private var isFlushingDeletes = false
    private var noticeDismissWorkItem: DispatchWorkItem?
    private var processedIdentifiers = Set<String>()
    private var processedIdentifiersOrder: [String] = []
    private var didLoadProcessedIdentifiers = false

    private let deleteBatchThreshold = 15
    private let deleteDelaySeconds: TimeInterval = 3.5
    private let processedIdentifiersLimit = 12000
    private let processedIdentifiersKey = "processedAssetIdentifiers"

    private let libraryManager = PhotoLibraryManager.shared

    // MARK: - Lifecycle

    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true
        loadProcessedIdentifiersIfNeeded()

        Task { await ensureAuthorization() }
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task { await refreshAuthorizationStatus() }
        case .inactive:
            break
        case .background:
            flushPendingDeletesIfNeeded()
        @unknown default:
            break
        }
    }

    // MARK: - User actions

    func keepCurrent() {
        guard let asset = currentAsset else { return }
        markAssetProcessed(asset)
        stats.kept += 1
        
        // Track for review
        ReviewManager.shared.recordPhotoProcessed()
        
        advanceToNextAsset()
    }

    func deleteCurrent() {
        guard let asset = currentAsset else { return }

        pendingDeleteQueue.append(asset)
        pendingDeleteStatsCount += 1
        pendingDeleteIdentifiers.insert(asset.id)
        pendingDeleteCount = pendingDeleteQueue.count
        stats.deleted += 1
        markAssetProcessed(asset)
        
        // Track for review
        ReviewManager.shared.recordPhotoProcessed()

        advanceToNextAsset()
        scheduleDeleteFlush()
    }

    func skipCurrent() {
        guard let asset = currentAsset else { return }
        stats.skipped += 1
        markAssetProcessed(asset)
        assetQueue.append(asset)
        
        // Track for review
        ReviewManager.shared.recordPhotoProcessed()
        
        advanceToNextAsset()
    }

    func reloadLibrary(resetStats: Bool) {
        Task { await reloadAssets(resetStats: resetStats) }
    }

    func selectAlbum(_ album: PhotoAlbum) {
        selectedAlbum = album
        Task { await reloadAssets(resetStats: false) }
    }

    func setDateFilter(_ filter: DateFilter) {
        guard filter != dateFilter else { return }
        dateFilter = filter
        Task { await reloadAssets(resetStats: false) }
    }

    func setMediaFilter(_ filter: MediaFilter) {
        guard filter != mediaFilter else { return }
        mediaFilter = filter
        Task { await reloadAssets(resetStats: false) }
    }

    func reloadAlbums() {
        refreshAlbumsList()
    }

    func resetStats() {
        stats = PhotoCleanerStats()
        pendingDeleteStatsCount = 0
        pendingDeleteCount = pendingDeleteQueue.count
    }

    func clearError() {
        errorMessage = nil
    }

    func clearNotice() {
        noticeDismissWorkItem?.cancel()
        noticeMessage = nil
    }

    func openSettings() {
        libraryManager.openSettings()
    }

    func presentLimitedLibraryPicker() {
        libraryManager.presentLimitedLibraryPicker()
    }

    func flushPendingDeletesIfNeeded() {
        guard !pendingDeleteQueue.isEmpty else { return }
        Task { await flushPendingDeletes(reason: .force) }
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() async {
        await ensureAuthorization(requestIfNeeded: false)
    }

    private func ensureAuthorization(requestIfNeeded: Bool = true) async {
        let previousState = authorizationState
        let currentStatus = libraryManager.currentAuthorizationStatus()

        updateAuthorizationState(with: currentStatus)
        var resolvedStatus = currentStatus

        if requestIfNeeded && !currentStatus.isAuthorized {
            authorizationState = .requesting
            resolvedStatus = await libraryManager.requestAuthorization()
            updateAuthorizationState(with: resolvedStatus)
        }

        if authorizationState.isAuthorized {
            let shouldResetStats = !previousState.isAuthorized
            let shouldReloadQueue = shouldResetStats || assetQueue.isEmpty
            if shouldReloadQueue {
                await reloadAssets(resetStats: shouldResetStats)
            }
        } else {
            assetQueue = []
            currentAsset = nil
            previewAsset = nil
            pendingDeleteQueue.removeAll()
            pendingDeleteStatsCount = 0
            pendingDeleteIdentifiers.removeAll()
            pendingDeleteCount = 0
            deleteWorkItem?.cancel()
            deleteWorkItem = nil
        }
    }

    private func updateAuthorizationState(with status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            authorizationState = .authorized
        case .limited:
            authorizationState = .limited
        case .denied, .restricted:
            authorizationState = .denied
        case .notDetermined:
            authorizationState = .idle
        @unknown default:
            authorizationState = .denied
        }
    }

    // MARK: - Asset management

    private func advanceToNextAsset() {
        guard !assetQueue.isEmpty else {
            currentAsset = nil
            previewAsset = nil
            // Reset stats when queue is empty (all photos skipped/reviewed)
            if stats.processed > 0 {
                stats = PhotoCleanerStats()
                pendingDeleteStatsCount = 0
                pendingDeleteCount = pendingDeleteQueue.count
            }
            return
        }

        currentAsset = assetQueue.removeFirst()
        previewAsset = assetQueue.first

        if let previewAsset {
            libraryManager.refreshCacheAround(
                asset: previewAsset,
                targetSize: CGSize(width: 420, height: 420)
            )
        }
    }

    private func reloadAssets(resetStats: Bool) async {
        guard authorizationState.isAuthorized else { return }

        await flushPendingDeletes(reason: .force)

        isLoadingAssets = true
        defer { isLoadingAssets = false }

        let includeVideos = includeVideos
        let randomize = randomizeQueue
        let albumForFetch: PhotoAlbum? = selectedAlbum.collection == nil ? nil : selectedAlbum
        let currentMediaFilter = mediaFilter

        let fetched = libraryManager.fetchAssets(
            includeVideos: includeVideos,
            randomize: randomize,
            album: albumForFetch,
            dateFilter: dateFilter,
            mediaFilter: currentMediaFilter
        )
        loadProcessedIdentifiersIfNeeded()
        let assets = fetched.filter { !pendingDeleteIdentifiers.contains($0.id) && !processedIdentifiers.contains($0.id) }
        assetQueue = assets
        advanceToNextAsset()

        if resetStats {
            stats = PhotoCleanerStats()
            pendingDeleteStatsCount = 0
        }

        refreshAlbumsList()
    }

    // MARK: - Deletion batching

    private func scheduleDeleteFlush() {
        deleteWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                await self?.flushPendingDeletes(reason: .force)
            }
        }

        deleteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + deleteDelaySeconds, execute: workItem)

        if pendingDeleteQueue.count >= deleteBatchThreshold {
            Task { await flushPendingDeletes(reason: .threshold) }
        }
    }

    private func flushPendingDeletes(reason _: FlushReason) async {
        guard !isFlushingDeletes else { return }
        guard !pendingDeleteQueue.isEmpty else {
            pendingDeleteCount = 0
            deleteWorkItem?.cancel()
            deleteWorkItem = nil
            return
        }

        isFlushingDeletes = true
        deleteWorkItem?.cancel()
        deleteWorkItem = nil

        let batch = pendingDeleteQueue
        pendingDeleteQueue.removeAll()
        pendingDeleteCount = pendingDeleteQueue.count
        let batchIdentifiers = batch.map(\.id)

        do {
            try await libraryManager.delete(assets: batch)
            pendingDeleteStatsCount = max(0, pendingDeleteStatsCount - batch.count)
            batchIdentifiers.forEach { pendingDeleteIdentifiers.remove($0) }
            
            // Successful deletion - good moment for review
            ReviewManager.shared.recordSuccessfulDeletion(count: batch.count)
        } catch {
            // Roll back optimistic stats and re-queue the assets for another attempt.
            let rollbackAmount = min(batch.count, pendingDeleteStatsCount)
            pendingDeleteStatsCount = max(0, pendingDeleteStatsCount - rollbackAmount)
            stats.deleted = max(0, stats.deleted - rollbackAmount)

            assetQueue = batch + assetQueue
            pendingDeleteQueue = batch + pendingDeleteQueue
            pendingDeleteCount = pendingDeleteQueue.count
            // identifiers stay in the set so filtered out until commit succeeds
            if currentAsset == nil {
                advanceToNextAsset()
            } else {
                previewAsset = assetQueue.first
            }

            if let libraryError = error as? PhotoLibraryError {
                switch libraryError {
                case .userCancelledDelete:
                    presentNotice("Silme işlemi iptal edildi. Fotoğraflar güvende.")
                case .deleteFailed(let message):
                    errorMessage = message
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isFlushingDeletes = false
    }

    private func refreshAlbumsList() {
        let fetched = libraryManager.fetchAlbums()
        var list = [PhotoAlbum(id: PhotoAlbum.allPhotos.id, title: PhotoAlbum.allPhotos.title, assetCount: assetQueue.count, collection: nil)]
        list.append(contentsOf: fetched)
        albums = list
        if !list.contains(selectedAlbum) {
            selectedAlbum = .allPhotos
        }
    }

    private func presentNotice(_ message: String) {
        noticeDismissWorkItem?.cancel()
        noticeMessage = message

        let workItem = DispatchWorkItem { [weak self] in
            self?.noticeMessage = nil
        }
        noticeDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
    }

    private func loadProcessedIdentifiersIfNeeded() {
        guard !didLoadProcessedIdentifiers else { return }
        didLoadProcessedIdentifiers = true
        let stored = UserDefaults.standard.stringArray(forKey: processedIdentifiersKey) ?? []
        processedIdentifiersOrder = stored
        processedIdentifiers = Set(stored)
    }

    private func persistProcessedIdentifiers() {
        UserDefaults.standard.set(processedIdentifiersOrder, forKey: processedIdentifiersKey)
    }

    private func markAssetProcessed(_ asset: PhotoAsset) {
        loadProcessedIdentifiersIfNeeded()
        let id = asset.id
        guard !processedIdentifiers.contains(id) else { return }
        processedIdentifiers.insert(id)
        processedIdentifiersOrder.append(id)

        trimProcessedIdentifiersIfNeeded()
        persistProcessedIdentifiers()
    }

    private func trimProcessedIdentifiersIfNeeded() {
        if processedIdentifiersOrder.count > processedIdentifiersLimit {
            let overflow = processedIdentifiersOrder.count - processedIdentifiersLimit
            let removed = processedIdentifiersOrder.prefix(overflow)
            processedIdentifiersOrder.removeFirst(overflow)
            removed.forEach { processedIdentifiers.remove($0) }
        }
    }
}

private extension PHAuthorizationStatus {
    var isAuthorized: Bool {
        self == .authorized || self == .limited
    }
}
