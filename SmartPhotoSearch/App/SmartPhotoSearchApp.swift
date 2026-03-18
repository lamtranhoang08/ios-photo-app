//
//  App/SmartPhotoSearchApp.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI
import FirebaseCore

@main
struct SmartPhotoSearchApp: App {
    // AppDelegate to handle background session callback
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

