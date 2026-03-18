//
//  Services/BackgroundUploadService+URLSessionTaskDelegate.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import Foundation

extension BackgroundUploadService: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        if let assetID = taskToAssetID[task.taskIdentifier] {
            DispatchQueue.main.async { [weak self] in
                self?.onProgress?(assetID, progress)
            }
        }
    }
}
