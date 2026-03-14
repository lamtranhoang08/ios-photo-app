import Photos
import UIKit
class PhotoLibraryService {
    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            print(status)
        }
    }
    
    func fetchPhotos(limit: Int = 50) -> [UIImage] {
        var images: [UIImage] = []
        
        // Fetch options: sort by creation date
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch assets
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        // Limit results
        let count = min(fetchResult.count, limit)
        let imageManager = PHCachingImageManager.default()
        
        let options = PHImageRequestOptions()
        // NOTE: Using synchronous image loading for simplicity.
        // TODO: Replace with async image loading + caching for large libraries.
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        
        for i in 0..<count {
            let asset = fetchResult.object(at: i)
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { (image, _) in
                if let image = image {
                    images.append(image)
                }
            }
        }
        
        return images
    }
}
