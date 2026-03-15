//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: GalleryViewModel = .init()
    
    @State private var columnsCount: Int = 3
    @State private var currentScale: CGFloat = 1.0
    
    let spacing: CGFloat = 2
    let minColumns: Int = 1
    let maxColumns: Int = 6
    
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
            .animation(.easeInOut(duration: 0.2), value: columnsCount)
        }
        .gesture(
            MagnificationGesture()
                .onChanged { scale in
                    // scale > 1 = zooming in (fewer columns)
                    // scale < 1 = zooming out (more columns)
                    currentScale = scale
                }
                .onEnded { scale in
                    let delta = scale > 1.2 ? -1 : scale < 0.8 ? 1 : 0
                    let newCount = (columnsCount + delta).clamped(to: minColumns...maxColumns)
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        columnsCount = newCount
                    }
                    
                    // reset for next gesture
                    currentScale = 1.0
                }
        )
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
