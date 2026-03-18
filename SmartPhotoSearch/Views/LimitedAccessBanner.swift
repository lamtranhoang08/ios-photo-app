//
//  Views/LimitedAccessBanner.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI

struct LimitedAccessBanner: View {
    @ObservedObject var viewModel: GalleryViewModel
    @Binding var isPresentingLimitedPicker: Bool

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
