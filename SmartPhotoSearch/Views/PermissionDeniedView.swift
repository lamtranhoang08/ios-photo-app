//
//  Views/PermissionDeniedView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Photo access is required")
                .font(.headline)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}
