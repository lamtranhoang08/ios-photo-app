//
//  Views/PermissionDeniedView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI

/// Displayed when the user has denied photo library access.
/// Provides a direct link to Settings so the user can grant permission.
struct PermissionDeniedView: View {

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Photo access is required")
                .font(.headline)

            Button("Open Settings") {
                openSettings()
            }
        }
    }

    // MARK: - Private

    /// Opens the app's page in iOS Settings.
    /// Safe to call — does nothing if URL is unavailable.
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
