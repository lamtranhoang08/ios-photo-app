//
//  Services/TagRepository.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 20/3/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol

/// Abstraction over tag persistence.
/// Decouples Vision tagging from Firestore — swap storage backend without touching VisionService.
/// Inject MockTagRepository in tests to avoid hitting Firestore.
protocol TagRepositoryProtocol {
    func saveTags(_ tags: [ImageTag], for assetID: String)
    func fetchTags(for assetID: String, completion: @escaping ([ImageTag]) -> Void)
}

// MARK: - Implementation

/// Persists Vision-generated tags to Firestore.
///
/// Uses merge: true on writes to preserve existing fields (downloadURL, faceIDs etc).
/// Firestore stores numbers as Double — Float conversion handled on read.
///
/// Scalability note: for large libraries, consider batching writes
/// using WriteBatch to reduce Firestore write operations.
class TagRepository: TagRepositoryProtocol {
    
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    
    // MARK: - Write
    
    /// Saves tags for an asset to Firestore.
    /// Uses merge: true — safe to call multiple times without overwriting other fields.
    func saveTags(_ tags: [ImageTag], for assetID: String) {
        let tagData: [[String: Any]] = tags.map { tag in
            [
                "identifier": tag.identifier,
                "confidence": tag.confidence
            ]
        }
        
        db.collection("photos")
            .document(sanitize(assetID))
            .setData(["tags": tagData], merge: true) { error in
                if let error {
                    print("Save tags failed [\(assetID)]: \(error.localizedDescription)")
                }
            }
    }
    
    // MARK: - Read
    
    /// Fetches tags for a single asset from Firestore.
    /// Returns empty array if document doesn't exist or has no tags.
    /// Firestore returns confidence as Double — cast to Float to match ImageTag.
    func fetchTags(for assetID: String, completion: @escaping ([ImageTag]) -> Void) {
        db.collection("photos")
            .document(sanitize(assetID))
            .getDocument { snapshot, error in
                if let error {
                    print("Fetch tags failed [\(assetID)]: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let data = snapshot?.data(),
                      let tagArray = data["tags"] as? [[String: Any]] else {
                    completion([])
                    return
                }
                
                let tags = tagArray.compactMap { dict -> ImageTag? in
                    guard
                        let identifier = dict["identifier"] as? String,
                        let confidence = dict["confidence"] as? Double
                    else { return nil }
                    // Firestore stores as Double — cast to Float to match ImageTag model
                    return ImageTag(identifier: identifier, confidence: Float(confidence))
                }
                
                completion(tags)
            }
    }
    
    // MARK: - Private
    
    // TODO: Extract to String+Sanitize.swift — same logic exists in BackgroundUploadService
    private func sanitize(_ assetID: String) -> String {
        assetID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
