//
//  Service/BackgroundUploadService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import Foundation
import Photos
import FirebaseStorage
import FirebaseFirestore

// MARK: - Protocol
protocol BackgroundUploadServiceProtocol {
    var backgroundCompletionHandler: (() -> Void)? { get set }
    func upload(
        data: Data,
        assetID: String,
        onProgress: ((Double) -> Void)?,
        onComplete: ((Result<String, Error>) -> Void)?
    )
}

class BackgroundUploadService: NSObject, BackgroundUploadServiceProtocol {
    // MARK: - Singleton
    static let shared = BackgroundUploadService()
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    // Tracks completion handler given to us by iOS when app wakes in background
    var backgroundCompletionHandler: (() -> Void)?

    // MARK: - Upload
    func upload(
        data: Data,
        assetID: String,
        onProgress: ((Double) -> Void)? = nil,
        onComplete: ((Result<String, Error>) -> Void)? = nil
    ) {
        // Build Firebase Storage upload URL manually
        let sanitizedID = sanitize(assetID)
        
        // Write data to temp file - background sessions require file uploads
        let tempURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("\(sanitizedID).jpg")
        
        do {
            try data.write(to: tempURL)
        } catch {
            onComplete?(.failure(error))
            return
        }
                
        let storageRef = Storage.storage()
            .reference()
            .child("photos/\(sanitizedID).jpg")
        
        let uploadTask = storageRef.putFile(from: tempURL, metadata: nil)
        
        // Progress via Firebase observer
        uploadTask.observe(.progress) { snapshot in
            let progress = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
            onProgress?(progress)
        }
        
        // Success
        uploadTask.observe(.success) { [weak self] _ in
            guard let self else { return }
            storageRef.downloadURL { url, error in
                if let url {
                    self.saveMetadata(assetID: assetID, downloadURL: url.absoluteString)
                    onComplete?(.success(url.absoluteString))
                } else {
                    onComplete?(.failure(error ?? UploadError.downloadURLFailed))
                }
            }
        }
        
        // Failure
        uploadTask.observe(.failure) { snapshot in
                   onComplete?(.failure(snapshot.error ?? UploadError.uploadFailed))
        }
        
    }
    
    // MARK: - Private
    private func saveMetadata(assetID: String, downloadURL: String) {
        let sanitizedID = sanitize(assetID)
        
        let data: [String: Any] = [
            "localIdentifier": assetID,
            "downloadURL": downloadURL,
            "uploadedAt": Date(),
            "tags": [],
            "faceIDs": []
        ]
        
        db.collection("photos")
            .document(sanitizedID)
            .setData(data) { error in
                if let error {
                    print("Metadata save failed: \(error.localizedDescription)")
                }
            }
    }
    
    private func sanitize(_ assetID: String) -> String {
        assetID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
    
}
