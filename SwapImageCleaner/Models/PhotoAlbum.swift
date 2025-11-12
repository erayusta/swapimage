import Photos

struct PhotoAlbum: Identifiable, Equatable {
    let id: String
    let title: String
    let assetCount: Int
    let collection: PHAssetCollection?

    static let allPhotos = PhotoAlbum(id: "all", title: "Tüm fotoğraflar", assetCount: 0, collection: nil)

    var displaySubtitle: String {
        assetCount > 0 ? "\(assetCount) öğe" : ""
    }

    static func == (lhs: PhotoAlbum, rhs: PhotoAlbum) -> Bool {
        lhs.id == rhs.id
    }
}
