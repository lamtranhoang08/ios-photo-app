//
//  LazyImageLoader.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//
import SwiftUI
import Combine
import Photos

class LazyImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private let asset: PHAsset
    private let manager = PHCachingImageManager.default()
    private var requestID: PHImageRequestID? //track request so we cancel
    private let accessQueue = DispatchQueue(label: "com.smartphotosearch.imageloader")
    
    // Basic cache
    static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200;
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        return cache
    }()
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    func loadImage(targetSize: CGSize) {
        
        // Check cache first
        if let cached = LazyImageLoader.imageCache.object(forKey: asset.localIdentifier as NSString) {
            self.image = cached
            return
        }
        
        // Async options
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        requestID = manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] img, info in
            guard let self else {return}
            
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            
            DispatchQueue.main.async {
                if let img {
                    self.image = img
                    // Only cache the final high-quality result
                    if !isDegraded {
                        LazyImageLoader.imageCache.setObject(
                            img,
                            forKey: self.asset.localIdentifier as NSString
                        )
                    }
                } else {
                    print("Failed to load image: \(self.asset.localIdentifier)")
                }
            }
        }
    }
    
    func cancel() {
        if let id = requestID {
            manager.cancelImageRequest(id)
            requestID = nil
        }
    }
}
