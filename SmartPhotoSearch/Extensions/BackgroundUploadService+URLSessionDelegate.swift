//
//  Serivces/BackgroundUploadService+URLSessionDelegate.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import Foundation

extension BackgroundUploadService: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }
}
