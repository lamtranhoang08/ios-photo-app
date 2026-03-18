//
//  LazyImageCell.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import SwiftUI
import Photos

struct LazyImageCell: View {
    let asset: PHAsset
    let uploadStatus: UploadStatus?
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @StateObject private var loader: LazyImageLoader
    
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
                    Color.gray.opacity(0.2)
                        .frame(width: size, height: size)
                }
                
                uploadOverlay(size: size)
                    .opacity(isSelectionMode ? 0 : 1)
                selectionOverlay(size: size)
            }
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
            .scaleEffect(isSelected ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    // Selection overlay — checkmark + dim
    @ViewBuilder
    private func selectionOverlay(size: CGFloat) -> some View {
        if isSelectionMode {
            let isUploaded = uploadStatus?.isUploaded ?? false
            ZStack {
                Color.black.opacity(isUploaded ? 0.4 : (isSelected ? 0.0 : 0.2))
                VStack {
                    HStack {
                        Spacer()
                        // Checkmark circle
                        ZStack {
                            if isUploaded {
                                // Show lock/cloud icon instead of selection circle
                                Image(systemName: "checkmark.icloud.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(6)
                            } else {
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
        case .done:
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
