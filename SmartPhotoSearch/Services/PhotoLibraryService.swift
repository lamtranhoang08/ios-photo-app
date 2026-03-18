//
//  Services/PhotoLibraryService.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import Photos
import UIKit
import PhotosUI

protocol PhotoLibraryServiceProtocol {
    func requestPhotoPermission(completion: @escaping (Bool) -> Void)
    func fetchAssets(limit: Int) -> [PHAsset]
    
}

class PhotoLibraryService: PhotoLibraryServiceProtocol {
    private let library: PHPhotoLibraryProtocol.Type
    
    init(library: PHPhotoLibraryProtocol.Type = LivePHPhotoLibrary.self) {
        self.library = library
    }
    
    func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
        library.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }
    
    func fetchAssets(limit: Int = 500) -> [PHAsset] {
        var assets: [PHAsset] = []
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let count = min(fetchResult.count, limit)
        
        for i in 0..<count {
            assets.append(fetchResult.object(at: i))
        }
        
        return assets
    }

}
