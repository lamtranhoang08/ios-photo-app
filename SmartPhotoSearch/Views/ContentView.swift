//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: GalleryViewModel = .init()
    @State private var isPresentingLimitedPicker: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LimitedAccessBanner(
                    viewModel: viewModel,
                    isPresentingLimitedPicker: $isPresentingLimitedPicker
                )

                GalleryGrid(viewModel: viewModel)
            }
            .navigationTitle("SmartPhotoSearch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                GalleryToolbar(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadPhotos()
            }
            .overlay {
                if viewModel.permissionDenied {
                    PermissionDeniedView()
                }
            }
            .background {
                LimitedPickerPresenter(isPresenting: $isPresentingLimitedPicker)
                    .frame(width: 0, height: 0)
            }
        }
    }
}

#Preview {
    ContentView()
}

