import Photos

struct PhotoAsset: Identifiable, Equatable {
    let id: String
    let asset: PHAsset

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }

    var creationDate: Date? {
        asset.creationDate
    }

    var mediaType: PHAssetMediaType {
        asset.mediaType
    }
}

func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
    lhs.id == rhs.id
}
