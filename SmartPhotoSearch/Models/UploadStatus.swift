//
//  Models/UploadStatus.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 17/3/26.
//

import Foundation
enum UploadStatus: Equatable {
    case pending
    case uploading(progress: Double)
    case done(downloadURL: String)
    case failed(error: String)
    case tagging
    case tagged(downloadURL: String)
    
    var isUploaded: Bool {
        switch self {
        case .done, .tagged: return true
        default: return false
        }
      }
}
