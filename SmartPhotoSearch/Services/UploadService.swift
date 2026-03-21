//
//  Services/UploadService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 17/3/26.
//

import Foundation
import Photos

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
    private let imageExtractor: ImageExtractorProtocol
    
    init(backgroundUploadService: BackgroundUploadServiceProtocol = BackgroundUploadService.shared,
         imageExtractor: ImageExtractorProtocol = ImageExtractor.shared
    ) {
        self.backgroundUploadService = backgroundUploadService
        self.imageExtractor = imageExtractor
    }
    
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
enum UploadError: LocalizedError {
    case uploadFailed
    case downloadURLFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed:          return "Failed to upload to Firebase"
        case .downloadURLFailed:     return "Failed to get download URL"
        }
    }
}
