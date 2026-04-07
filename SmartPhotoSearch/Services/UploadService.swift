//
//  Services/UploadService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 17/3/26.
//

import Foundation
import Photos

// MARK: - Protocol

/// Abstraction over the full upload pipeline.
/// Separates image extraction from transport so each can be swapped independently.
/// Inject MockUploadService in tests to avoid hitting Firebase.
protocol UploadServiceProtocol {
    func upload(
        asset: PHAsset,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    )
}

// MARK: - Implementation

/// Orchestrates the two-step upload pipeline:
/// 1. Extract JPEG data from PHAsset via ImageExtractor
/// 2. Upload data to Firebase Storage via BackgroundUploadService
///
/// Kept intentionally thin — all transport logic lives in BackgroundUploadService.
/// This makes it easy to swap storage backends (S3, Cloudinary) without touching callers.
class UploadService: UploadServiceProtocol {
    
    // MARK: - Dependencies
    private let backgroundUploadService: BackgroundUploadServiceProtocol
    private let imageExtractor: ImageExtractorProtocol
    
    // MARK: - Init
    init(
        backgroundUploadService: BackgroundUploadServiceProtocol = BackgroundUploadService.shared,
        imageExtractor: ImageExtractorProtocol = ImageExtractor.shared
    ) {
        self.backgroundUploadService = backgroundUploadService
        self.imageExtractor = imageExtractor
    }
    
    // MARK: - Upload
    
    /// Extracts JPEG data then delegates upload to BackgroundUploadService.
    /// Progress and completion are forwarded directly from the transport layer.
    func upload(
        asset: PHAsset,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        imageExtractor.extractData(from: asset) { [weak self] result in
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
}

// MARK: - Errors

/// Upload-specific errors.
/// ImageExtractor errors are handled separately in ImageExtractorError.
enum UploadError: LocalizedError {
    case uploadFailed
    case downloadURLFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed:      return "Failed to upload to Firebase Storage"
        case .downloadURLFailed: return "Failed to retrieve download URL after upload"
        }
    }
}
