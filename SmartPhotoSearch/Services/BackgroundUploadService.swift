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
    var onProgress: ((String, Double) -> Void)? { get set }
    var onComplete: ((String, Result<String, Error>) -> Void)? { get set }
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
    private var backgroundSession: URLSession!
    private let db = Firestore.firestore()
    private let sessionIdentifier = "com.smartphotosearch.backgroundupload"
    
    // Tracks completion handler given to us by iOS when app wakes in background
    var backgroundCompletionHandler: (() -> Void)?
    
    // Track which assetID corresponds to which upload task
    var taskToAssetID: [Int: String] = [:]
    
    // Progress callbacks per assetID - used to update UI
    var onProgress: ((String, Double) -> Void)?
    var onComplete: ((String, Result<String, Error>) -> Void)?
    
    // MARK: - Init
    override init() {
        super.init( )
        setupBackgroundSession()
    }
    
    private func setupBackgroundSession() {
        let config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        config.isDiscretionary = false // upload ASAP
        config.sessionSendsLaunchEvents = true // wake app when upload completes
        
        backgroundSession = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    // MARK: - Upload
    func upload(
        data: Data,
        assetID: String,
        onProgress: ((Double) -> Void)? = nil,
        onComplete: ((Result<String, Error>) -> Void)? = nil
    ) {
        // Build Firebase Storage upload URL manually
        let sanitizedID = assetID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        
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
        
        // Use background URLSession  upload task
        storageRef.putFile(from: tempURL, metadata: nil) { [weak self] metadata, error in
            guard let self else { return }
            
            if let error {
                onComplete?(.failure(error))
                return
            }
            
            // Get download URL after successful upload
            storageRef.downloadURL { url, error in
                if let url {
                    // Save metadata to Firestore
                    self.saveMetadata(assetID: assetID, downloadURL: url.absoluteString)
                    onComplete?(.success(url.absoluteString))
                } else {
                    onComplete?(.failure(error ?? UploadError.downloadURLFailed))
                }
            }
        }
    }
    
    // MARK: - Metadata
    private func saveMetadata(assetID: String, downloadURL: String) {
        let sanitizedID = assetID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        
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
    
}
