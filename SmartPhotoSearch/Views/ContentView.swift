//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: GalleryViewModel = .init()

    let columnsCount = 3
    let spacing: CGFloat = 2
    
    @ViewBuilder
        private var permissionDeniedView: some View {
            if viewModel.permissionDenied {
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
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount),
                spacing: spacing
            ) {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                    LazyImageCell(asset: asset)
                }
            }
            .padding(.horizontal, spacing)
        }
        .onAppear {
            viewModel.loadPhotos()
        }
        .overlay{
            permissionDeniedView
        }
    }
}

#Preview {
    ContentView()
}
