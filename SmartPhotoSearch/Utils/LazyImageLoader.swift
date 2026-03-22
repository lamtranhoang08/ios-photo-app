//
//  Utils/LazyImageLoader.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import SwiftUI
import Photos
import Combine

/// Drives async image loading for a single PHAsset.
///
/// Wraps ImageRequestStore (actor) for thread-safe request tracking,
/// and a shared NSCache for fast repeated access without hitting PhotoKit again.
///
/// Usage: create one instance per cell via @StateObject,
/// call loadImage(targetSize:) on appear, cancel() on disappear.
class LazyImageLoader: ObservableObject {

    // MARK: - Published State
    @Published var image: UIImage?

    // MARK: - Private
    private let asset: PHAsset
    private let store: ImageRequestStore

    // MARK: - Shared Cache
    /// Shared across all LazyImageLoader instances.
    /// Limits: 200 images or 100MB — whichever is hit first.
    /// NSCache evicts automatically under memory pressure.
    static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024
        return cache
    }()

    // MARK: - Init
    init(asset: PHAsset) {
        self.asset = asset
        self.store = ImageRequestStore(manager: PHCachingImageManager.default())
    }

    // MARK: - Public Interface

    /// Loads the image for the asset at the given target size.
    /// Returns immediately from cache if available.
    /// Uses .opportunistic delivery — shows degraded preview first,
    /// then upgrades to full quality. Only the final result is cached.
    func loadImage(targetSize: CGSize) {
        let key = asset.localIdentifier as NSString

        if let cached = LazyImageLoader.imageCache.object(forKey: key) {
            self.image = cached
            return
        }

        Task {
            await store.request(for: asset, targetSize: targetSize) { [weak self] img, info in
                guard let self else { return }

                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                DispatchQueue.main.async {
                    if let img {
                        self.image = img
                        // Only cache the final high-quality result —
                        // degraded previews are not worth storing
                        if !isDegraded {
                            LazyImageLoader.imageCache.setObject(img, forKey: key)
                        }
                    } else {
                        print("⚠️ Failed to load image: \(self.asset.localIdentifier)")
                    }
                }
            }
        }
    }

    /// Cancels any in-flight image request for this asset.
    /// Call from onDisappear to free system resources when cells scroll off screen.
    func cancel() {
        Task {
            await store.cancel()
        }
    }
}
