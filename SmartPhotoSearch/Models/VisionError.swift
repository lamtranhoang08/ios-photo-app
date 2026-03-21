//
//  Models/VisionError.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 20/3/26.
//

import Foundation

enum VisionError: LocalizedError {
    case imageExtractionFailed
    case classificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageExtractionFailed:
            return "Failed to extract image for classification"
        case .classificationFailed(let reason):
            return "Classification failed: \(reason)"
        }
    }
}
