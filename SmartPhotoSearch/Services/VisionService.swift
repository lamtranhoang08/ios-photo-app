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
protocol VisionServiceProtocol {
    func classifyImage(
        from asset: PHAsset,
        completion: @escaping (Result<[ImageTag], Error>) -> Void
    )
}

// MARK: - Implementation
class VisionService: VisionServiceProtocol {
    // only keep tags above this confidence threshold
    private let confidenceThreshold: Float = 0.5
    private let imageExtractor: ImageExtractorProtocol
    
    init(imageExtractor: ImageExtractorProtocol = ImageExtractor.shared) {
        self.imageExtractor = imageExtractor
    }
    
    func classifyImage(
        from asset: PHAsset,
        completion: @escaping (Result<[ImageTag], Error>) -> Void
    ) {
        // 512x512 is enough for classification — no need for full res
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
    
    private func classify(
           image: UIImage,
           completion: @escaping (Result<[ImageTag], Error>) -> Void
       ) {
           guard let cgImage = image.cgImage else {
               completion(.failure(VisionError.imageExtractionFailed))
               return
           }

           // Step 1 — create request
           let request = VNClassifyImageRequest { [weak self] request, error in
               guard let self else { return }

               if let error {
                   completion(.failure(VisionError.classificationFailed(error.localizedDescription)))
                   return
               }

               // Step 2 — read results
               guard let results = request.results as? [VNClassificationObservation] else {
                   completion(.failure(VisionError.classificationFailed("No results")))
                   return
               }

               // Step 3 — filter by confidence + map to ImageTag
               let tags = results
                   .filter { $0.confidence >= self.confidenceThreshold }
                   .map { ImageTag(identifier: $0.identifier, confidence: $0.confidence) }
                   .sorted { $0.confidence > $1.confidence } // highest confidence first

               completion(.success(tags))
           }

           // Step 4 — perform on background queue
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
