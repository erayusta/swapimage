import Photos
import PhotosUI
import UIKit

enum PhotoLibraryError: LocalizedError, Equatable {
    case userCancelledDelete
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .userCancelledDelete:
            return "Silme işlemi iptal edildi."
        case .deleteFailed(let message):
            return message
        }
    }
}

final class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()

    private let cachingManager = PHCachingImageManager()

    private init() {}

    func currentAuthorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchAssets(includeVideos: Bool, randomize: Bool, album: PhotoAlbum?, dateFilter: DateFilter, mediaFilter: MediaFilter) -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        var predicates: [NSPredicate] = []

        // Media type predicate based on mediaFilter
        if let mediaType = mediaFilter.mediaType {
            predicates.append(NSPredicate(format: "mediaType == %d", mediaType.rawValue))
        } else {
            // All media types
            if includeVideos {
                predicates.append(
                    NSPredicate(
                        format: "mediaType == %d OR mediaType == %d",
                        PHAssetMediaType.image.rawValue,
                        PHAssetMediaType.video.rawValue
                    )
                )
            } else {
                predicates.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue))
            }
        }

        if let datePredicate = dateFilter.predicateReferenceDate() {
            predicates.append(datePredicate)
        }

        if !predicates.isEmpty {
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        let fetchResult: PHFetchResult<PHAsset>

        if let collection = album?.collection {
            fetchResult = PHAsset.fetchAssets(in: collection, options: options)
        } else {
            fetchResult = PHAsset.fetchAssets(with: options)
        }
        var assets: [PhotoAsset] = []
        assets.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(PhotoAsset(asset: asset))
        }

        if randomize {
            assets.shuffle()
        }

        primeImageCache(with: assets)

        return assets
    }

    func fetchAlbums() -> [PhotoAlbum] {
        var albums: [PhotoAlbum] = []

        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        albums.append(contentsOf: mapCollections(userAlbums))

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        albums.append(contentsOf: mapCollections(smartAlbums))

        return albums.sorted { $0.title.lowercased() < $1.title.lowercased() }
    }

    func refreshCacheAround(asset: PhotoAsset, targetSize: CGSize) {
        let scaledSize = pixelSize(for: targetSize)
        cachingManager.startCachingImages(
            for: [asset.asset],
            targetSize: scaledSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    func requestImage(for asset: PhotoAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill, completion: @escaping (UIImage?) -> Void) {
        let scaledSize = pixelSize(for: targetSize)
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        cachingManager.requestImage(
            for: asset.asset,
            targetSize: scaledSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func delete(assets: [PhotoAsset]) async throws {
        guard !assets.isEmpty else { return }

        let nativeAssets = assets.map(\.asset) as NSArray

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(nativeAssets)
            }) { success, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == PHPhotosErrorDomain,
                       PHPhotosError.Code(rawValue: nsError.code) == .userCancelled {
                        continuation.resume(throwing: PhotoLibraryError.userCancelledDelete)
                        return
                    }
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(
                        throwing: PhotoLibraryError.deleteFailed(
                            "Silme işlemi bilinmeyen bir nedenle başarısız oldu."
                        )
                    )
                }
            }
        }
    }

    func presentLimitedLibraryPicker() {
        guard currentAuthorizationStatus() == .limited else { return }

        guard let root = topViewController() else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: root)
    }

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
    }

    // MARK: - Helpers

    private func pixelSize(for targetSize: CGSize) -> CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: max(targetSize.width, 1) * scale, height: max(targetSize.height, 1) * scale)
    }

    private func primeImageCache(with assets: [PhotoAsset]) {
        let chunk = assets.prefix(12).map(\.asset)
        cachingManager.startCachingImages(
            for: Array(chunk),
            targetSize: pixelSize(for: CGSize(width: 500, height: 500)),
            contentMode: .aspectFill,
            options: nil
        )
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC: UIViewController? = {
            if let base {
                return base
            }

            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController
        }()

        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = baseVC?.presentedViewController {
            return topViewController(base: presented)
        }
        return baseVC
    }

    private func mapCollections(_ collections: PHFetchResult<PHAssetCollection>) -> [PhotoAlbum] {
        var albums: [PhotoAlbum] = []
        collections.enumerateObjects { [weak self] collection, _, _ in
            guard let self, self.shouldInclude(collection: collection) else { return }
            let fetchOptions = PHFetchOptions()
            let count = PHAsset.fetchAssets(in: collection, options: fetchOptions).count
            if count == 0 { return }
            let title = collection.localizedTitle ?? "Albüm"
            let album = PhotoAlbum(id: collection.localIdentifier, title: title, assetCount: count, collection: collection)
            albums.append(album)
        }
        return albums
    }

    private func shouldInclude(collection: PHAssetCollection) -> Bool {
        switch collection.assetCollectionSubtype {
        case .smartAlbumAllHidden:
            return false
        case .smartAlbumUserLibrary:
            return false
        default:
            return true
        }
    }
}
