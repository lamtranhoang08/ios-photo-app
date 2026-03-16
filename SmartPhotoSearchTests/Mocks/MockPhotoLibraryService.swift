//
//  MockPhotoLibraryService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//


import Photos
@testable import SmartPhotoSearch
import UIKit

class MockPhotoLibraryService: PhotoLibraryServiceProtocol {
    
    // MARK: - Control knobs (set these in each test)
    var shouldGrantPermission: Bool = true
    var assetsToReturn: [PHAsset] = []
    
    // MARK: - Call tracking (verify these in each test)
    var requestPermissionCallCount: Int = 0
    var fetchAssetsCallCount: Int = 0
    var lastFetchLimit: Int?
    
    func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
        requestPermissionCallCount += 1
        completion(shouldGrantPermission)
    }
    
    func fetchAssets(limit: Int) -> [PHAsset] {
        fetchAssetsCallCount += 1
        lastFetchLimit = limit
        return assetsToReturn
    }
    
    func presentLimitedLibraryPicker(from viewController: UIViewController) {
    }
}
