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
    
    var isUploaded: Bool {
          if case .done = self { return true }
          return false
      }
}
