//
//  GalleryViewModel.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import Foundation
import SwiftUI
import Photos
import FirebaseFirestore
import Combine

@MainActor
class GalleryViewModel : NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    // only keep references to photos
    // suitable for scale project
    @Published var assets: [PHAsset] = []
    @Published var permissionDenied: Bool = false
    @Published var isLimited: Bool = false //new
    @Published var uploadStatuses: [String: UploadStatus] = [:]
    @Published var isSelectionMode: Bool = false
    @Published var selectedAssetIDs: Set<String> = []
    
    private let photoService: PhotoLibraryServiceProtocol
    private let uploadService: UploadServiceProtocol
    
    init(photoService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
         uploadService: UploadServiceProtocol = UploadService()
    ) {
        self.photoService = photoService
        self.uploadService = uploadService
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        // Always unregister — prevents memory leaks
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.reloadAfterLimitedExpansion()
        }
    }
    
    func loadPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            isLimited = false
            loadAssets()
            syncUploadStatuses()
        case .limited:
            isLimited = true
            loadAssets()
            syncUploadStatuses()
        case .notDetermined:
            photoService.requestPhotoPermission { [weak self] granted in
                if granted { self?.loadPhotos() }
            }
        case .denied, .restricted:
            permissionDenied = true
            // TODO: Show a UI alert directing user to Settings
            break
        @unknown default: break
        }
    }
    
    // TODO: Move Firestore access to PhotoRepository in Milestone 2
    func syncUploadStatuses() {
        let db = Firestore.firestore()
        
        db.collection("photos").getDocuments { [weak self] snapshot, error in
            guard let self else { return }
            
            if let error {
                print("Failed to sync upload statuses: \(error.localizedDescription)")
                return
            }
            
            Task { @MainActor in
                snapshot?.documents.forEach { doc in
                    let assetID = doc.data()["localIdentifier"] as? String ?? doc.documentID
                        .replacingOccurrences(of: "_", with: "/")
                    
                    let downloadURL = doc.data()["downloadURL"] as? String ?? ""
                    self.uploadStatuses[assetID] = .done(downloadURL: downloadURL)
                }
            }
        }
    }
    
    private func loadAssets() {
        Task.detached(priority: .userInitiated) {
            [weak self] in
            let fetched = self?.photoService.fetchAssets(limit: 200) ?? []
            await MainActor.run { self?.assets = fetched}
        }
    }
    
    func reloadAfterLimitedExpansion() {
        isLimited = false
        loadAssets()
    }
    
    func uploadAll() {
        // Only upload assets that haven't been uploaded yet
        let pending = assets.filter { asset in
            uploadStatuses[asset.localIdentifier] == nil ||
            uploadStatuses[asset.localIdentifier] == .pending
        }
        
        for asset in pending {
            uploadAsset(asset)
        }
    }
    
    func uploadSelected() {
        let toUpload = assets.filter { selectedAssetIDs.contains($0.localIdentifier) }
        for asset in toUpload {
            uploadAsset(asset)
        }
        toggleSelectionMode()
    }
    
    func uploadAsset(_ asset: PHAsset) {
        let id = asset.localIdentifier
        uploadStatuses[id] = .uploading(progress: 0.0)
        
        uploadService.upload(
            asset: asset,
            onProgress: { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.uploadStatuses[id] = .uploading(progress: progress)
                }
            },
            onComplete: { [weak self] result in
                Task { @MainActor [weak self] in
                    switch result {
                    case .success(let url):
                        self?.uploadStatuses[id] = .done(downloadURL: url)
                    case .failure(let error):
                        print("Upload failed for \(id): \(error.localizedDescription)")
                        self?.uploadStatuses[id] = .failed(error: error.localizedDescription)
                    }
                }
            }
        )
    }
    
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedAssetIDs.removeAll()
        }
    }
    
    func toggleSelection(for asset: PHAsset) {
        guard uploadStatuses[asset.localIdentifier]?.isUploaded != true else { return }
        let id = asset.localIdentifier
        if selectedAssetIDs.contains(id) {
            selectedAssetIDs.remove(id)
        } else {
            selectedAssetIDs.insert(id)
        }
    }
}
