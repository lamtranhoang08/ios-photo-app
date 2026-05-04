//
//  Service/DeleteService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 4/5/26.
//

import Photos
import FirebaseFirestore
import FirebaseStorage

protocol DeleteServiceProtocol {
    func delete(
        assetIDs: [String],
        assets: [PHAsset],
        onComplete:  @escaping (Result<Void, Error>) -> Void
    )
}

enum DeleteError: LocalizedError {
    case photoLibraryDenied
    case photoLibraryFailed(Error)
    case firebaseFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .photoLibraryDenied:
            return "Photo library denied"
        case .photoLibraryFailed(let error):
            return "Failed to delete from library: \(error.localizedDescription)"
        case .firebaseFailed(let error):
            return "Failed to delete from cloud: \(error.localizedDescription)"
        }
    }
}

class DeleteService: DeleteServiceProtocol {
    static let shared = DeleteService()
    private let db = Firestore.firestore()
    
    /// Deletes assets from both the device library and Firebase
    /// Device delete happens first. If it faules, do not call delete from Firebase
    func delete(assetIDs: [String], assets: [PHAsset], onComplete: @escaping (Result<Void, any Error>) -> Void) {
        deleteFromDevice(assets: assets) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                onComplete(.failure(error))
            case .success:
                self.deleteFromFirebase(assetIDs: assetIDs, onComplete: onComplete)
            }
        }
    }
    
    // MARK: -Device Delete
    private func deleteFromDevice(assets: [PHAsset], onComplete: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        } completionHandler: { success, error in
            DispatchQueue.main.sync {
                if success {
                    onComplete(.success(()))
                } else if let error {
                    onComplete(.failure(DeleteError.photoLibraryFailed(error)))
                } else {
                    onComplete(.failure(DeleteError.photoLibraryDenied))
                }
            }
        }
    }
    
    // MARK: - Firebase Delete
    /// Deletes Firestore document and Storate file for each asset
    /// Uses a DispatchGroup so onComplete fires only after all deletes finish
    private func deleteFromFirebase(assetIDs: [String], onComplete: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        var firstError: Error? = nil
        
        for assetID in assetIDs {
            let sanitizedID = sanitize(assetID)
            
            // Delete Firestore doc
            group.enter()
            Storage.storage()
                .reference()
                .child("photos/\(sanitizedID).jpg")
                .delete { error in
                    if let error = error as NSError?,
                       error.domain != StorageErrorDomain {
                        firstError = DeleteError.firebaseFailed(error)
                    }
                    group.leave()
                }
        }
        group.notify(queue: .main) {
            if let error = firstError {
                onComplete(.failure(error))
            } else {
                onComplete(.success(()))
            }
        }
    }
    
    private func sanitize(_ assetID: String) -> String {
        assetID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
