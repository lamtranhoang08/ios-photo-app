//
//  Views/LazyImageCell.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import SwiftUI
import Photos

/// A single photo cell in the gallery grid.
/// Displays a lazy-loaded thumbnail with overlays for:
/// - Upload progress (uploading / done / failed / tagging)
/// - Selection state (multi-select mode)
struct LazyImageCell: View {

    // MARK: - Properties
    let asset: PHAsset
    let uploadStatus: UploadStatus?
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @StateObject private var loader: LazyImageLoader

    // MARK: - Init
    init(
        asset: PHAsset,
        uploadStatus: UploadStatus? = nil,
        isSelectionMode: Bool = false,
        isSelected: Bool = false,
        onTap: @escaping () -> Void = {},
        onLongPress: @escaping () -> Void = {}
    ) {
        self.asset = asset
        self.uploadStatus = uploadStatus
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.onTap = onTap
        self.onLongPress = onLongPress
        _loader = StateObject(wrappedValue: LazyImageLoader(asset: asset))
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width
            let targetSize = CGSize(
                width: size * UITraitCollection.current.displayScale,
                height: size * UITraitCollection.current.displayScale
            )

            ZStack {
                Color.gray.opacity(0.2)

                if let img = loader.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    // Placeholder while image loads
                    Color.gray.opacity(0.2)
                        .frame(width: size, height: size)
                }

                // Upload overlay hidden during selection mode to avoid
                // visual conflict with the selection checkmark
                uploadOverlay(size: size)
                    .opacity(isSelectionMode ? 0 : 1)

                selectionOverlay(size: size)
            }
            .frame(width: size, height: size)
            .clipped()
            // Explicit Rectangle content shape ensures tap zone
            // matches the visual cell exactly — prevents adjacent
            // cell tap misregistration in LazyVGrid
            .contentShape(Rectangle())
            .onAppear {
                loader.loadImage(targetSize: targetSize)
            }
            .onDisappear {
                loader.cancel()
            }
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture {
                onLongPress()
            }
            // Subtle scale feedback when cell is selected
            .scaleEffect(isSelected ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Selection Overlay

    /// Shows a selection circle (or uploaded cloud icon) when in selection mode.
    /// Uploaded photos show a cloud checkmark and are visually dimmed
    /// to indicate they are not selectable.
    @ViewBuilder
    private func selectionOverlay(size: CGFloat) -> some View {
        if isSelectionMode {
            let isUploaded = uploadStatus?.isUploaded ?? false

            ZStack {
                // Dim uploaded cells more strongly to signal non-selectability
                Color.black.opacity(isUploaded ? 0.4 : (isSelected ? 0.0 : 0.2))

                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            if isUploaded {
                                // Cloud icon — already synced, not selectable
                                Image(systemName: "checkmark.icloud.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(6)
                            } else {
                                // Selection circle
                                Circle()
                                    .fill(isSelected ? Color.blue : Color.white.opacity(0.6))
                                    .frame(width: 24, height: 24)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(6)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Upload Overlay

    /// Shows upload state feedback on top of the thumbnail.
    /// States: uploading (progress bar) → tagging (spinner) → done (checkmark) → failed (warning)
    @ViewBuilder
    private func uploadOverlay(size: CGFloat) -> some View {
        switch uploadStatus {
        case .uploading(let progress):
            ZStack {
                Color.black.opacity(0.4)
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .frame(width: size * 0.7)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }

        case .tagging:
            // Vision framework is running on-device classification
            ZStack {
                Color.black.opacity(0.4)
                VStack(spacing: 4) {
                    ProgressView()
                        .tint(.white)
                    Text("Tagging...")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }

        case .done, .tagged:
            // Both done and tagged show the same green checkmark
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .background(Color.white.clipShape(Circle()))
                        .padding(4)
                }
                Spacer()
            }

        case .failed:
            ZStack {
                Color.red.opacity(0.3)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
            }

        case .pending, .none:
            EmptyView()
        }
    }
}
