//
//  Services/PhotoLibraryService.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import Photos
import PhotosUI

// MARK: - Protocol

/// Abstraction over all photo library operations.
/// Inject MockPhotoLibraryService in tests to avoid requiring real device permissions.
protocol PhotoLibraryServiceProtocol {
    func requestPhotoPermission(completion: @escaping (Bool) -> Void)
    func fetchAssets(limit: Int) -> [PHAsset]
    func presentLimitedLibraryPicker(from viewController: UIViewController)
}

// MARK: - Implementation

/// Bridges PhotoKit APIs for permission management and asset fetching.
///
/// Uses PHPhotoLibraryProtocol for authorization — allows MockPHPhotoLibrary
/// injection in unit tests without triggering real permission dialogs.
///
/// Scalability note: fetchAssets currently loads all assets up to limit into memory.
/// For libraries > 10,000 photos, consider lazy enumeration via PHFetchResult
/// directly rather than materialising the full array.
class PhotoLibraryService: PhotoLibraryServiceProtocol {

    // MARK: - Dependencies
    private let library: PHPhotoLibraryProtocol.Type

    // MARK: - Init
    init(library: PHPhotoLibraryProtocol.Type = LivePHPhotoLibrary.self) {
        self.library = library
    }

    // MARK: - Permission

    /// Requests read/write photo library access.
    /// Completion is always called on the main thread — safe to update UI directly.
    /// Returns true for both .authorized and .limited — app handles both cases.
    func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
        library.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    // MARK: - Fetching

    /// Fetches PHAsset references sorted by creation date (newest first).
    /// Returns references only — no image data loaded at this layer.
    /// Caller is responsible for image loading via PHImageManager.
    func fetchAssets(limit: Int = 500) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let count = min(fetchResult.count, limit)

        // PHFetchResult is lazy — object(at:) is O(1), array materialisation is O(n)
        return (0..<count).map { fetchResult.object(at: $0) }
    }

    // MARK: - Limited Access

    /// Presents Apple's native picker for expanding limited photo access.
    /// iOS 15+ only. Falls back to Settings on earlier versions via LimitedPickerPresenter.
    func presentLimitedLibraryPicker(from viewController: UIViewController) {
        if #available(iOS 17, *) {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController) { _ in }
        } else {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: viewController)
        }
    }
}
