//
//  GalleryViewModel.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import Photos

@MainActor
class GalleryViewModel : ObservableObject {
    // only keep references to photos
    // suitable for scale project
    @Published var assets: [PHAsset] = []
    @Published var permissionDenied: Bool = false
    
    private let photoService: PhotoLibraryServiceProtocol
    
    init(photoService: PhotoLibraryServiceProtocol = PhotoLibraryService()) {
        self.photoService = photoService
    }
    
    func loadPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            Task.detached(priority: .userInitiated) { [weak self] in
                let fetched = self?.photoService.fetchAssets(limit: 500) ?? []
                await MainActor.run { self?.assets = fetched }
            }
        case .notDetermined:
            photoService.requestPhotoPermission { [weak self] granted in
                if granted { self?.loadPhotos() }
            }
        case .denied, .restricted:
            self.permissionDenied = true
            // TODO: Show a UI alert directing user to Settings
            break
        @unknown default: break
        }
    }
}
