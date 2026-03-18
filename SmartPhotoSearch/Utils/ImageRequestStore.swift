//
//  utils/ImageRequestStore.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//

import SwiftUI
import Combine
import Photos

actor ImageRequestStore {
    private var requestID: PHImageRequestID?
    private let manager: PHImageManager
    
    init(manager: PHImageManager) {
        self.manager = manager
    }
    
    func request(
           for asset: PHAsset,
           targetSize: CGSize,
           completion: @escaping (UIImage?, [AnyHashable: Any]?) -> Void
       ) -> PHImageRequestID {
           let options = PHImageRequestOptions()
           options.isSynchronous = false
           options.deliveryMode = .opportunistic
           options.resizeMode = .fast
           options.isNetworkAccessAllowed = true

           let id = manager.requestImage(
               for: asset,
               targetSize: targetSize,
               contentMode: .aspectFill,
               options: options,
               resultHandler: completion
           )

           //  actor guarantees only one writer at a time
           requestID = id
           return id
       }
    
    func cancel() {
        if let id = requestID {
            manager.cancelImageRequest(id)
            requestID = nil
        }
    }
}
