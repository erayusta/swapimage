import Foundation
import Photos

enum MediaFilter: String, CaseIterable, Identifiable {
    case all
    case photosOnly
    case videosOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Tümü"
        case .photosOnly:
            return "Sadece Fotoğraflar"
        case .videosOnly:
            return "Sadece Videolar"
        }
    }

    var subtitle: String? {
        switch self {
        case .all:
            return "Fotoğraf ve video"
        case .photosOnly:
            return "Sadece fotoğrafları göster"
        case .videosOnly:
            return "Sadece videoları göster"
        }
    }

    var mediaType: PHAssetMediaType? {
        switch self {
        case .all:
            return nil
        case .photosOnly:
            return .image
        case .videosOnly:
            return .video
        }
    }
}
