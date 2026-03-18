//
//  Services/PHPhotoLibraryProtocol.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//


import Photos

protocol PHPhotoLibraryProtocol {
    static func requestAuthorization (
        for accessLevel: PHAccessLevel,
        handler: @escaping (PHAuthorizationStatus) -> Void
    )
        
    static func authorizationStatus(for accessLevel: PHAccessLevel) -> PHAuthorizationStatus
}

class LivePHPhotoLibrary: PHPhotoLibraryProtocol {
    static func requestAuthorization(
        for accessLevel: PHAccessLevel,
        handler: @escaping (PHAuthorizationStatus) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization(for: accessLevel, handler: handler)
    }
    
    static func authorizationStatus(
        for accessLevel: PHAccessLevel
    ) -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: accessLevel)
    }
}
