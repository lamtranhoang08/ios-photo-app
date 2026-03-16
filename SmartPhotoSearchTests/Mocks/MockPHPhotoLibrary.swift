//
//  MockPHPhotoLibrary.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//

import Photos
@testable import SmartPhotoSearch

class MockPHPhotoLibrary: PHPhotoLibraryProtocol {
    
    // MARK: - Control knobs
    static var statusToReturn: PHAuthorizationStatus = .notDetermined
    static var shouldGrantOnRequest: Bool = true
    
    // MARK: - Call tracking
    static var requestAuthorizationCallCount: Int = 0
    static var authorizationStatusCallCount: Int = 0
    
    // MARK: - Reset between tests
    static func reset() {
        statusToReturn = .notDetermined
        shouldGrantOnRequest = true
        requestAuthorizationCallCount = 0
        authorizationStatusCallCount = 0
    }
    
    static func requestAuthorization(
        for accessLevel: PHAccessLevel,
        handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        requestAuthorizationCallCount += 1
        let result: PHAuthorizationStatus = shouldGrantOnRequest ? .authorized : .denied
        handler(result)
    }
    
    static func authorizationStatus(
        for accessLevel: PHAccessLevel
    ) -> PHAuthorizationStatus {
        authorizationStatusCallCount += 1
        return statusToReturn
    }
}
