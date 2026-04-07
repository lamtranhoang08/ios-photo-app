//
//  Services/PHPhotoLibraryProtocol.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//

import Photos

// MARK: - Protocol

/// Abstracts Apple's static PHPhotoLibrary API behind an instance protocol.
///
/// PHPhotoLibrary exposes authorization via static methods which cannot be
/// directly mocked in unit tests. This protocol wraps those calls so
/// MockPHPhotoLibrary can be injected in tests without touching the real library.
///
/// Only the two authorization methods are wrapped — PHAsset fetching
/// uses instance methods and is testable via PHFetchResult directly.
protocol PHPhotoLibraryProtocol {
    static func requestAuthorization(
        for accessLevel: PHAccessLevel,
        handler: @escaping (PHAuthorizationStatus) -> Void
    )
    static func authorizationStatus(
        for accessLevel: PHAccessLevel
    ) -> PHAuthorizationStatus
}

// MARK: - Live Implementation

/// Production wrapper around PHPhotoLibrary's static methods.
/// Used as the default in PhotoLibraryService.
/// Swapped for MockPHPhotoLibrary in unit tests.
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
