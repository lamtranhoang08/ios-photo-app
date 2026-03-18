//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel: GalleryViewModel = .init()
    
    @State private var columnsCount: Int = 3
    @State private var currentScale: CGFloat = 1.0
    @State private var isPresentingLimitedPicker: Bool = false
    
    let spacing: CGFloat = 2
    let minColumns: Int = 1
    let maxColumns: Int = 6
    
    @ViewBuilder
    private var limitedAccessBanner: some View {
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
        NavigationStack {
            VStack(spacing: 0) {
                limitedAccessBanner
                
                ScrollView {
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: spacing),
                            count: columnsCount
                        ),
                        spacing: spacing
                    ) {
                        ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                            LazyImageCell(
                                asset: asset,
                                uploadStatus: viewModel.uploadStatuses[asset.localIdentifier]
                            )
                        }
                    }
                    .padding(.horizontal, spacing)
                    .animation(.easeInOut(duration: 0.2), value: columnsCount)
                }
                .gesture(
                    MagnificationGesture()
                        .onEnded { scale in
                            let delta = scale > 1.2 ? -1 : scale < 0.8 ? 1 : 0
                            let newCount = (columnsCount + delta)
                                .clamped(to: minColumns...maxColumns)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                columnsCount = newCount
                            }
                        }
                )
            }
            .navigationTitle("SmartPhotoSearch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            .onAppear {
                viewModel.loadPhotos()
            }
            .overlay {
                permissionDeniedView
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
