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
    @Published var tags: [String: [ImageTag]] = [:]  // assetID → tags
    
    private let photoService: PhotoLibraryServiceProtocol
    private let uploadService: UploadServiceProtocol
    private let visionService: VisionServiceProtocol
    private let tagRepository: TagRepositoryProtocol
    
    init(photoService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
         uploadService: UploadServiceProtocol = UploadService(),
         visionService: VisionServiceProtocol = VisionService(),
         tagRepository: TagRepositoryProtocol = TagRepository()
    ) {
        self.photoService = photoService
        self.uploadService = uploadService
        self.visionService = visionService
        self.tagRepository = tagRepository
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
            syncTags()
        case .limited:
            isLimited = true
            loadAssets()
            syncUploadStatuses()
            syncTags()
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
                        self?.tagAsset(asset)
                    case .failure(let error):
                        print("Upload failed for \(id): \(error.localizedDescription)")
                        self?.uploadStatuses[id] = .failed(error: error.localizedDescription)
                    }
                }
            }
        )
    }
    
    func tagAll() {
        let untagged = assets.filter { tags[$0.localIdentifier] == nil }
        for asset in untagged {
            tagAsset(asset)
        }
    }
    
    func tagAsset(_ asset: PHAsset) {
        let id = asset.localIdentifier
        
        Task { @MainActor in
            // only tag if upload is done
            if case .done(let url) = self.uploadStatuses[id] {
                self.uploadStatuses[id] = .tagging
                self.performTagging(asset: asset, id: id, downloadURL: url)
            }
        }
    }
    
    private func performTagging(asset: PHAsset, id: String, downloadURL: String) {
        visionService.classifyImage(from: asset) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let imageTags):
                self.tagRepository.saveTags(imageTags, for: id)
                Task { @MainActor in
                    self.tags[id] = imageTags
                    self.uploadStatuses[id] = .tagged(downloadURL: downloadURL)
                    print("Tagged: \(imageTags.prefix(3).map(\.identifier))")
                }
                
            case .failure(let error):
                print("Tagging failed: \(error.localizedDescription)")
                // Fall back to .done — upload succeeded even if tagging failed
                Task { @MainActor in
                    self.uploadStatuses[id] = .done(downloadURL: downloadURL)
                }
            }
        }
    }
    
    func syncTags() {
        let db = Firestore.firestore()
        
        db.collection("photos").getDocuments { [weak self] snapshot, error in
            guard let self else { return }
            
            if let error {
                print("Failed to sync tags: \(error.localizedDescription)")
                return
            }
            
            Task { @MainActor in
                snapshot?.documents.forEach { doc in
                    let assetID = doc.data()["localIdentifier"] as? String ?? ""
                    guard !assetID.isEmpty else { return }
                    
                    let tagArray = doc.data()["tags"] as? [[String: Any]] ?? []
                    let tags = tagArray.compactMap { dict -> ImageTag? in
                        guard
                            let identifier = dict["identifier"] as? String,
                            let confidence = dict["confidence"] as? Double
                        else { return nil }
                        return ImageTag(identifier: identifier, confidence: Float(confidence))
                    }
                    
                    if !tags.isEmpty {
                        self.tags[assetID] = tags
                    }
                }
            }
        }
    }
    
    func reloadAfterLimitedExpansion() {
        isLimited = false
        loadAssets()
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
