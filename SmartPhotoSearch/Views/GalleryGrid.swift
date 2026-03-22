//
//  Views/GalleryGrid.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI
import Photos

/// Lazy-loading photo grid with:
/// - Pinch to zoom (1–6 columns, dead zone prevents accidental reflow)
/// - Long press to enter multi-select mode
/// - Tap to open full-screen photo detail
/// - Upload and selection state overlays per cell
struct GalleryGrid: View {

    // MARK: - Dependencies
    @ObservedObject var viewModel: GalleryViewModel

    // MARK: - Grid State
    /// Current number of columns. Adjusted by pinch gesture.
    @State private var columnsCount: Int = 3

    /// Index of the tapped photo. Setting this triggers navigation to PhotoDetailView.
    @State private var selectedIndex: Int? = nil

    // MARK: - Constants
    let minColumns: Int = 1
    let maxColumns: Int = 6
    let spacing: CGFloat = 2

    // MARK: - Body
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: spacing),
                    count: columnsCount
                ),
                spacing: spacing
            ) {
                ForEach(
                    Array(viewModel.assets.enumerated()),
                    id: \.element.localIdentifier
                ) { index, asset in
                    let isUploaded = viewModel.uploadStatuses[asset.localIdentifier]?.isUploaded ?? false

                    LazyImageCell(
                        asset: asset,
                        uploadStatus: viewModel.uploadStatuses[asset.localIdentifier],
                        isSelectionMode: viewModel.isSelectionMode,
                        isSelected: viewModel.selectedAssetIDs.contains(asset.localIdentifier),
                        onTap: {
                            handleTap(on: asset, at: index, isUploaded: isUploaded)
                        },
                        onLongPress: {
                            handleLongPress(on: asset, isUploaded: isUploaded)
                        }
                    )
                }
            }
            .padding(.horizontal, spacing)
            // Animate grid reflow when column count changes
            .animation(.easeInOut(duration: 0.2), value: columnsCount)
        }
        // Pinch to zoom — dead zone (0.8–1.2) prevents accidental reflow
        // during normal scrolling. Commits on gesture end, not on drag,
        // to avoid flickering from mid-gesture layout recalculations.
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

    // MARK: - Gesture Handlers

    /// Handles cell tap based on current mode:
    /// - Selection mode: toggles selection (uploaded photos are not selectable)
    /// - Normal mode: opens photo detail view
    private func handleTap(on asset: PHAsset, at index: Int, isUploaded: Bool) {
        if viewModel.isSelectionMode {
            guard !isUploaded else { return }
            viewModel.toggleSelection(for: asset)
        } else {
            selectedIndex = index
        }
    }

    /// Long press enters selection mode and auto-selects the pressed cell.
    /// Uploaded photos cannot enter selection mode via long press.
    private func handleLongPress(on asset: PHAsset, isUploaded: Bool) {
        guard !isUploaded, !viewModel.isSelectionMode else { return }
        viewModel.toggleSelectionMode()
        viewModel.toggleSelection(for: asset)
    }
}
