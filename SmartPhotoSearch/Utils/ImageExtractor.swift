//
//  Utils/ImageExtractor.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 20/3/26.
//

import Photos
import UIKit

// MARK: - Protocol
protocol ImageExtractorProtocol {
    func extractImage(
        from asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (Result<UIImage, Error>) -> Void
    )
    
    func extractData(
        from asset: PHAsset,
        completion: @escaping (Result<Data, Error>) -> Void
    )
}

// MARK: - Error
enum ImageExtractorError: LocalizedError {
    case extractionFailed
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .extractionFailed:  return "Failed to extract image from asset"
        case .compressionFailed: return "Failed to compress image to JPEG"
        }
    }
}

// MARK: - Implementation
class ImageExtractor: ImageExtractorProtocol {
    
    static let shared = ImageExtractor()
    
    func extractImage(
        from asset: PHAsset,
        targetSize: CGSize = CGSize(width: 512, height: 512),
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled { return }
            if let image {
                completion(.success(image))
            } else {
                let error = info?[PHImageErrorKey] as? Error
                completion(.failure(error ?? ImageExtractorError.extractionFailed))
            }
        }
    }
    
    func extractData(
        from asset: PHAsset,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // full resolution for upload
        extractImage(from: asset, targetSize: PHImageManagerMaximumSize) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let image):
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    completion(.failure(ImageExtractorError.compressionFailed))
                    return
                }
                completion(.success(data))
            }
        }
    }
}
