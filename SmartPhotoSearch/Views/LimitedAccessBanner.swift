//
//  Views/LimitedAccessBanner.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI

/// A banner shown when the user has granted limited photo library access.
/// Prompts the user to expand their selection via Apple's native photo picker.
/// Only visible when `viewModel.isLimited` is true.
struct LimitedAccessBanner: View {

    // MARK: - Dependencies
    @ObservedObject var viewModel: GalleryViewModel

    /// Controls presentation of the limited photo picker sheet.
    @Binding var isPresentingLimitedPicker: Bool

    // MARK: - Body
    var body: some View {
        if viewModel.isLimited {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Limited Access")
                            .font(.footnote.bold())
                        Text("You're only seeing some photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Triggers Apple's native limited photo picker
                    Button("Expand") {
                        isPresentingLimitedPicker = true
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))

                Divider()
            }
        }
    }
}
