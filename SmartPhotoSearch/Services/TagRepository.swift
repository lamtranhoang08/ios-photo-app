//
//  Services/TagRepository.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 20/3/26.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol TagRepositoryProtocol {
    func saveTags(_ tags: [ImageTag], for assetID: String)
    func fetchTags(for assetID: String, completion: @escaping ([ImageTag]?) -> Void)
}

// MARK: - Implementation
class TagRepository: TagRepositoryProtocol {
    private let db = Firestore.firestore()
    
    func saveTags(_ tags: [ImageTag], for assetID: String) {
        let tagData = tags.map {tag in
            [
                "identifier": tag.identifier,
                "confidence": tag.confidence
            ] as [String: Any]
        }
        
        // merge: true - preserves downloadURL and other existing fields
        db.collection("photos")
            .document(sanitize(assetID))
            .setData(["tags": tagData], merge: true) { error in
                if let error {
                    print("Failed to save tags: \(error.localizedDescription)")
                }
            }
    }
    
    func fetchTags(for assetID: String, completion: @escaping ([ImageTag]?) -> Void) {
        db.collection("photos")
            .document(sanitize(assetID))
            .getDocument { snapshot, _ in
                guard let data = snapshot?.data(),
                      let tagArray = data["tags"] as? [[String: Any]] else {
                    completion([])
                    return
                }
                
                let tags = tagArray.compactMap { dict -> ImageTag? in
                    guard let identifier = dict["identifier"] as? String,
                          let confidence = dict["confidence"] as? Double
                    else {
                        return nil
                    }
                    return ImageTag(identifier: identifier, confidence: Float(confidence))
                }
                completion(tags)
            }
    }
    
    // MARK: private
    // TODO: Extract sanitize() to String+Sanitize.swift — DRY violation
    private func sanitize(_ assetID: String) -> String {
        assetID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
