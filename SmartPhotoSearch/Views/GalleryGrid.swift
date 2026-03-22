//
//  Views/GalleryGrid.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI
import Photos

struct GalleryGrid: View {
    @ObservedObject var viewModel: GalleryViewModel
    
    @State private var columnsCount: Int = 3
    @State private var selectedIndex: Int? = nil
    
    let minColumns: Int = 1
    let maxColumns: Int = 6
    let spacing: CGFloat = 2
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: spacing),
                    count: columnsCount
                ),
                spacing: spacing
            ) {
                ForEach(Array(viewModel.assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                    let isUploaded = viewModel.uploadStatuses[asset.localIdentifier]?.isUploaded ?? false
                    
                    LazyImageCell(
                        asset: asset,
                        uploadStatus: viewModel.uploadStatuses[asset.localIdentifier],
                        isSelectionMode: viewModel.isSelectionMode,
                        isSelected: viewModel.selectedAssetIDs.contains(asset.localIdentifier),
                        onTap: {
                            if viewModel.isSelectionMode {
                                // selection mode — select/deselect
                                guard !isUploaded else { return }
                                viewModel.toggleSelection(for: asset)
                            } else {
                                // normal mode — open detail view
                                selectedIndex = index
                            }
                        },
                        onLongPress: {
                            guard !isUploaded else { return }
                            if !viewModel.isSelectionMode {
                                viewModel.toggleSelectionMode()
                                viewModel.toggleSelection(for: asset)
                            }
                        }
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
        .navigationDestination(item: $selectedIndex) { index in
            PhotoDetailView(
                assets: viewModel.assets,
                initialIndex: index,
                tagsMap: viewModel.tags
            )
        }
    }
}
