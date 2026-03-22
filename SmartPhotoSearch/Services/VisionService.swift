//
//  Services/VisionService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 19/3/26.
//

import Vision
import UIKit
import Photos

// MARK: - Protocol

/// Abstraction over Apple's Vision framework for image classification.
/// Protocol allows MockVisionService injection in unit tests,
/// bypassing the Neural Engine requirement (simulator incompatible).
protocol VisionServiceProtocol {
    func classifyImage(
        from asset: PHAsset,
        completion: @escaping (Result<[ImageTag], Error>) -> Void
    )
}

// MARK: - Implementation

/// On-device image classifier using Apple's Vision framework.
///
/// Uses VNClassifyImageRequest which runs on the Neural Engine —
/// available on iPhone 8+ with no network required.
/// Classifier runs on a background queue to keep the main thread free.
class VisionService: VisionServiceProtocol {

    // MARK: - Dependencies
    private let imageExtractor: ImageExtractorProtocol

    // MARK: - Constants
    /// Tags below this threshold are too uncertain to be useful.
    /// 0.5 = 50% confidence minimum — balances recall vs precision.
    private let confidenceThreshold: Float = 0.5

    // MARK: - Init
    init(imageExtractor: ImageExtractorProtocol = ImageExtractor.shared) {
        self.imageExtractor = imageExtractor
    }

    // MARK: - Public Interface

    /// Classifies a PHAsset and returns tags sorted by confidence (highest first).
    /// Uses 512×512 resolution — sufficient for classification,
    /// avoids loading full-resolution image unnecessarily.
    func classifyImage(
        from asset: PHAsset,
        completion: @escaping (Result<[ImageTag], Error>) -> Void
    ) {
        imageExtractor.extractImage(
            from: asset,
            targetSize: CGSize(width: 512, height: 512)
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let image):
                self.classify(image: image, completion: completion)
            }
        }
    }

    // MARK: - Private

    /// Runs VNClassifyImageRequest on a background queue.
    /// Filters by confidence threshold and sorts results descending.
    private func classify(
        image: UIImage,
        completion: @escaping (Result<[ImageTag], Error>) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(.failure(VisionError.imageExtractionFailed))
            return
        }

        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let self else { return }

            if let error {
                completion(.failure(VisionError.classificationFailed(error.localizedDescription)))
                return
            }

            guard let results = request.results as? [VNClassificationObservation] else {
                completion(.failure(VisionError.classificationFailed("No results returned")))
                return
            }

            let tags = results
                .filter { $0.confidence >= self.confidenceThreshold }
                .map { ImageTag(identifier: $0.identifier, confidence: $0.confidence) }
                .sorted { $0.confidence > $1.confidence }

            completion(.success(tags))
        }

        // Vision requests must not run on the main thread —
        // they block for 100–500ms depending on model complexity
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(VisionError.classificationFailed(error.localizedDescription)))
            }
        }
    }
}
