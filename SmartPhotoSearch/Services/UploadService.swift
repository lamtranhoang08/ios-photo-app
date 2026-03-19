//
//  Services/UploadService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 17/3/26.
//

import Foundation
import Photos
import UIKit
import FirebaseFirestore
import FirebaseStorage

// MARK: - Protocol
protocol UploadServiceProtocol {
    func upload(asset: PHAsset,
                onProgress: @escaping (Double) -> Void,
                onComplete: @escaping (Result<String, Error>) -> Void
    )
}

// MARK: - Implementation
class UploadService: UploadServiceProtocol {
    private let backgroundUploadService: BackgroundUploadServiceProtocol
    
    init(backgroundUploadService: BackgroundUploadServiceProtocol = BackgroundUploadService.shared) {
        self.backgroundUploadService = backgroundUploadService
    }
    
    func upload(
        asset: PHAsset,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        extractImageData(from: asset) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                onComplete(.failure(error))
                
            case .success(let data):
                self.backgroundUploadService.upload(
                    data: data,
                    assetID: asset.localIdentifier,
                    onProgress: onProgress,
                    onComplete: onComplete
                )
            }
        }
    }
    
    // MARK: - Private
    
    private func extractImageData(
        from asset: PHAsset, completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) {
            image, _ in
            guard let image,
                  let data = image.jpegData(compressionQuality: 0.8) else {
                completion(.failure(UploadError.imageExtractionFailed))
                return
            }
            completion(.success(data))
        }
    }
}

// MARK: - Errors
enum UploadError: LocalizedError {
    case imageExtractionFailed
    case uploadFailed
    case downloadURLFailed
    
    var errorDescription: String? {
        switch self {
        case .imageExtractionFailed: return "Failed to extract image data"
        case .uploadFailed:          return "Failed to upload to Firebase"
        case .downloadURLFailed:     return "Failed to get download URL"
        }
    }
}
