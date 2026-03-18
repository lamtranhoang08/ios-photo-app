//
//  App/AppDelegate.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import UIKit
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase here instead of SmartPhotoSearchApp.init()
        FirebaseApp.configure()
        return true
    }
    
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == "com.smartphotosearch.backgroundupload" {
            BackgroundUploadService.shared.backgroundCompletionHandler = completionHandler
        }
    }
}
