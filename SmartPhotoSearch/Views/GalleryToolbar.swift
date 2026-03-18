//
//  Views/GalleryToolbar.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//


import SwiftUI

struct GalleryToolbar: ToolbarContent {
    @ObservedObject var viewModel: GalleryViewModel

    var body: some ToolbarContent {
        // Left — cancel selection
        ToolbarItem(placement: .topBarLeading) {
            if viewModel.isSelectionMode {
                Button("Cancel") {
                    viewModel.toggleSelectionMode()
                }
            }
        }

        // Right — context sensitive
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isSelectionMode {
                Button {
                    viewModel.uploadSelected()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("Upload (\(viewModel.selectedAssetIDs.count))")
                            .font(.footnote.bold())
                    }
                }
                .disabled(viewModel.selectedAssetIDs.isEmpty)
            } else {
                Button {
                    viewModel.uploadAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "icloud.and.arrow.up")
                        Text("Upload All")
                            .font(.footnote.bold())
                    }
                }
            }
        }
    }
}
