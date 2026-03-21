//
//  Models/ImageTag.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 20/3/26.
//

import Foundation

struct ImageTag: Identifiable, Hashable, Codable {
    let id: UUID
    let identifier: String
    let confidence: Float
    
    init(identifier: String, confidence: Float) {
        self.id = UUID()
        self.identifier = identifier
        self.confidence = confidence
    }
    
    var displayText: String {
        "\(identifier) (\(Int(confidence * 100))%)"
    }
}
