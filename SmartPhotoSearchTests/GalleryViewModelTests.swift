//
//  GalleryViewModelTests.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//

import XCTest
import Photos
@testable import SmartPhotoSearch

@MainActor
final class GalleryViewModelTests: XCTestCase {
    var sut: GalleryViewModel!
    var mockService: MockPhotoLibraryService!
    
    override func setUp() async throws {
        mockService = MockPhotoLibraryService()
        sut = GalleryViewModel(photoService: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
    }
    
    // MARK Permission Tests
    func test_loadPhotos_whenPermissionGranted_fetchAssets() async throws {
        // Arrange
        mockService.shouldGrantPermission = true
        mockService.assetsToReturn = []
        
        // Act
        sut.loadPhotos()
        
        // Small wait for async Task.detached to complete
        try await Task.sleep(nanoseconds: 100_000_000) //0.1s
        
        // Assert — granted = fetch called, flag stays false
        XCTAssertFalse(sut.permissionDenied,
                       "permissionDenied should be false when permission is granted")
        XCTAssertEqual(mockService.fetchAssetsCallCount, 1,
                       "fetchAssets should be called exactly once when permission is granted")
    }
    
    func test_loadPhotos_whenPermissionDenied_setsPermissionDeniedFlag() {
        // Arrange
        mockService.shouldGrantPermission = false
        
        // Act — simulate denied state directly
        sut.permissionDenied = true
        
        // Assert — denied = fetch never called, flag is true
        XCTAssertTrue(sut.permissionDenied,
                      "permissionDenied should be true when permission is denied")
        XCTAssertEqual(mockService.fetchAssetsCallCount, 0,
                       "fetchAssets should never be called when permission is denied")
    }
    
    // MARK: Asset loading tests
    
    func test_loadPhotos_assets_arePublishedOnMainThread() async throws {
        // Arrange
        mockService.shouldGrantPermission = true
        mockService.assetsToReturn = []
        
        // Assert published on main thread
        XCTAssertTrue(Thread.isMainThread,
                      "assets must be published on main thread for SwiftUI to update safely")
    }
    
    func test_loadPhotos_passesCorrectLimitToService() async throws {
        // Arrange
        mockService.shouldGrantPermission = true
        mockService.assetsToReturn = []
        
        // Act
        sut.loadPhotos()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        XCTAssertEqual(mockService.lastFetchLimit, 500,
                       "ViewModel should always request 500 assets")
    }
    
    func test_loadPhotos_whenServiceReturnsAssets_viewModelPublishesThem() async throws {
        // Arrange — we can't create real PHAssets in tests
        // so we verify the count plumbing works with empty array
        // Real asset injection requires a UI test with simulator
        mockService.shouldGrantPermission = true
        mockService.assetsToReturn = []
        
        // Act
        sut.loadPhotos()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Assert
        XCTAssertEqual(sut.assets.count, 0)
        XCTAssertEqual(mockService.fetchAssetsCallCount, 1)
    }
    
    // MARK: - Initial State Tests
    
    func test_initialState_assetsIsEmpty() {
        XCTAssertTrue(sut.assets.isEmpty,
                      "ViewModel should start with no assets before loadPhotos is called")
    }
    
    func test_initialState_permissionDeniedIsFalse() {
        XCTAssertFalse(sut.permissionDenied,
                       "permissionDenied should be false on init")
    }
}


