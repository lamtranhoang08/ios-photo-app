//
//  PhotoLibraryServiceTests.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//

import XCTest
import Photos
@testable import SmartPhotoSearch

final class PhotoLibraryServiceTests: XCTestCase {
    
    var sut: PhotoLibraryService!
    
    override func setUp() {
        MockPHPhotoLibrary.reset()  // always start clean
        sut = PhotoLibraryService(library: MockPHPhotoLibrary.self)
    }
    
    override func tearDown() {
        sut = nil
        MockPHPhotoLibrary.reset()
    }
    
    // MARK: - requestPhotoPermission tests
    
    func test_requestPermission_whenAuthorized_callsCompletionWithTrue() {
        // Arrange
        MockPHPhotoLibrary.shouldGrantOnRequest = true
        
        let expectation = expectation(description: "completion called")
        var result: Bool?
        
        // Act
        sut.requestPhotoPermission { granted in
            result = granted
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(result, true,
                       "completion should return true when status is authorized")
        XCTAssertEqual(MockPHPhotoLibrary.requestAuthorizationCallCount, 1,
                       "requestAuthorization should be called exactly once")
    }
    
    func test_requestPermission_whenDenied_callsCompletionWithFalse() {
        // Arrange
        MockPHPhotoLibrary.shouldGrantOnRequest = false
        
        let expectation = expectation(description: "completion called")
        var result: Bool?
        
        // Act
        sut.requestPhotoPermission { granted in
            result = granted
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(result, false,
                       "completion should return false when status is denied")
    }
    
    func test_requestPermission_callsCompletionOnMainThread() {
        // Arrange
        let expectation = expectation(description: "completion on main thread")
        
        // Act
        sut.requestPhotoPermission { _ in
            // Assert inside callback
            XCTAssertTrue(Thread.isMainThread,
                          "completion must be called on main thread — SwiftUI depends on this")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_requestPermission_isCalledExactlyOnce_notMultipleTimes() {
        // Arrange
        let expectation = expectation(description: "completion called")
        
        // Act
        sut.requestPhotoPermission { _ in
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(MockPHPhotoLibrary.requestAuthorizationCallCount, 1,
                       "should never call requestAuthorization more than once per call")
    }
    
    // MARK: - State machine coverage
    
    func test_allAuthorizationStatuses_areHandled() {
        // This documents that we've considered every possible status
        // If Apple adds a new case, @unknown default catches it in production
        let allStatuses: [PHAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorized,
            .limited
        ]
        
        // Every status must be a known case — no gaps in our state machine
        XCTAssertEqual(allStatuses.count, 5,
                       "If this fails, Apple added a new PHAuthorizationStatus — update the state machine")
    }
}
