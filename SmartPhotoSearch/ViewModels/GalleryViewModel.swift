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

/// The central ViewModel driving all gallery UI state.
///
/// Responsibilities:
/// - Photo library access and permission handling
/// - Asset fetching and pagination
/// - Upload pipeline orchestration
/// - On-device Vision tagging pipeline
/// - Multi-select mode state
/// - Sync of upload statuses and tags from Firestore on launch
///
/// Threading: all @Published mutations happen on @MainActor.
/// Background work uses Task.detached or service callbacks.
@MainActor
class GalleryViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {

    // MARK: - Published State

    /// PHAsset references only — no UIImage held in memory at this layer
    @Published var assets: [PHAsset] = []

    /// True when user has denied photo library access
    @Published var permissionDenied: Bool = false

    /// True when user has granted limited (selected photos) access
    @Published var isLimited: Bool = false

    /// Upload + tagging state per asset, keyed by localIdentifier
    @Published var uploadStatuses: [String: UploadStatus] = [:]

    /// True when multi-select mode is active
    @Published var isSelectionMode: Bool = false

    /// Set of localIdentifiers currently selected
    @Published var selectedAssetIDs: Set<String> = []

    /// Vision-generated tags per asset, keyed by localIdentifier
    @Published var tags: [String: [ImageTag]] = [:]

    // MARK: - Dependencies (injected for testability)
    private let photoService: PhotoLibraryServiceProtocol
    private let uploadService: UploadServiceProtocol
    private let visionService: VisionServiceProtocol
    private let tagRepository: TagRepositoryProtocol

    // MARK: - Init
    init(
        photoService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
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
        // Unregister prevents a dangling observer and potential crash
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: - PHPhotoLibraryChangeObserver

    /// Called by iOS when the photo library changes (e.g. user expands limited access).
    /// nonisolated required by the Objective-C protocol — bridges back to MainActor via Task.
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.reloadAfterLimitedExpansion()
        }
    }

    // MARK: - Photo Loading

    /// Entry point — checks authorization status and routes to the appropriate flow.
    /// Loads assets, syncs upload statuses, and syncs tags on success.
    func loadPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            isLimited = false
            loadAssets()
            syncFromFirestore()

        case .limited:
            isLimited = true
            loadAssets()
            syncFromFirestore()

        case .notDetermined:
            photoService.requestPhotoPermission { [weak self] granted in
                if granted { self?.loadPhotos() }
            }

        case .denied, .restricted:
            permissionDenied = true

        @unknown default:
            break
        }
    }

    /// Fetches PHAsset references off the main thread.
    /// Only stores references — no images loaded at this layer.
    private func loadAssets() {
        Task.detached(priority: .userInitiated) { [weak self] in
            let fetched = self?.photoService.fetchAssets(limit: 200) ?? []
            await MainActor.run { self?.assets = fetched }
        }
    }

    /// Reloads assets after the user expands limited photo access.
    func reloadAfterLimitedExpansion() {
        isLimited = false
        loadAssets()
    }

    // MARK: - Upload

    /// Uploads all assets that are not yet uploaded or pending.
    /// Already-uploaded assets are skipped automatically.
    func uploadAll() {
        let pending = assets.filter { asset in
            uploadStatuses[asset.localIdentifier] == nil ||
            uploadStatuses[asset.localIdentifier] == .pending
        }
        pending.forEach { uploadAsset($0) }
    }

    /// Uploads only the currently selected assets, then exits selection mode.
    func uploadSelected() {
        assets
            .filter { selectedAssetIDs.contains($0.localIdentifier) }
            .forEach { uploadAsset($0) }
        toggleSelectionMode()
    }

    /// Orchestrates the upload pipeline for a single asset.
    /// On success, automatically triggers on-device Vision tagging.
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
                        // Auto-tag after successful upload
                        self?.tagAsset(asset)
                    case .failure(let error):
                        print("Upload failed [\(id)]: \(error.localizedDescription)")
                        self?.uploadStatuses[id] = .failed(error: error.localizedDescription)
                    }
                }
            }
        )
    }

    // MARK: - Tagging

    /// Tags all assets that have not been tagged yet.
    /// Only assets with a .done upload status are eligible.
    func tagAll() {
        assets
            .filter { tags[$0.localIdentifier] == nil }
            .forEach { tagAsset($0) }
    }

    /// Initiates on-device Vision tagging for a single asset.
    /// Only runs if the asset's upload status is .done — ensures
    /// the photo exists in Firebase before writing tags.
    func tagAsset(_ asset: PHAsset) {
        let id = asset.localIdentifier
        Task { @MainActor in
            guard case .done(let url) = self.uploadStatuses[id] else { return }
            self.uploadStatuses[id] = .tagging
            self.performTagging(asset: asset, id: id, downloadURL: url)
        }
    }

    /// Runs VNClassifyImageRequest on the asset and persists results.
    /// Falls back to .done status if classification fails so the upload
    /// state is never left in a broken state.
    private func performTagging(asset: PHAsset, id: String, downloadURL: String) {
        visionService.classifyImage(from: asset) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let imageTags):
                self.tagRepository.saveTags(imageTags, for: id)
                Task { @MainActor in
                    self.tags[id] = imageTags
                    self.uploadStatuses[id] = .tagged(downloadURL: downloadURL)
                    print("Tagged [\(id)]: \(imageTags.prefix(3).map(\.identifier))")
                }
            case .failure(let error):
                print("Tagging failed [\(id)]: \(error.localizedDescription)")
                // Upload succeeded — don't penalise with a failed state
                Task { @MainActor in
                    self.uploadStatuses[id] = .done(downloadURL: downloadURL)
                }
            }
        }
    }

    // MARK: - Firestore Sync
    // TODO: Move both sync methods to a PhotoRepository in Milestone 3
    // Currently accessing Firestore directly from ViewModel for simplicity
    
    /// Single Firestore query that restores both upload statuses and tags on launch.
    /// Replaces two separate network calls — halves Firestore reads on app start.
    /// TODO: Move to PhotoRepository in Milestone 3
    func syncFromFirestore() {
        Firestore.firestore().collection("photos").getDocuments { [weak self] snapshot, error in
            guard let self else { return }
            
            if let error {
                print("sync failed: \(error.localizedDescription)")
                return
            }
            
            Task { @MainActor in
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    
                    // restore upload status
                    guard let assetID = data["localIdentifier"] as? String,
                          !assetID.isEmpty else { return }
                    let downloadURL = data["downloadURL"] as? String ?? ""
                    self.uploadStatuses[assetID] = .done(downloadURL: downloadURL)
                        
                    // restore tags if present
                    let tagArray = data["tags"] as? [[String: Any]] ?? []
                    let imageTags = tagArray.compactMap { dict -> ImageTag? in
                        guard
                            let identifier = dict["identifier"] as? String,
                            let confidence = dict["confidence"] as? Double
                        else { return nil }
                        return ImageTag(identifier: identifier, confidence: Float(confidence))
                    }
                    if !imageTags.isEmpty {
                        self.tags[assetID] = imageTags
                    }
                }
            }
        }
    }

    // MARK: - Selection

    /// Toggles multi-select mode on/off.
    /// Clears all selections when exiting to prevent stale state.
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedAssetIDs.removeAll()
        }
    }

    /// Toggles selection for a single asset.
    /// Uploaded assets are not selectable — guard prevents mis-selection.
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
