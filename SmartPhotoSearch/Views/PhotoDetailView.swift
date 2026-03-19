//
//  View/PhotoDetailView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 19/3/26.
//

import SwiftUI
import Photos

struct PhotoDetailView: View {
    let asset: PHAsset
    @StateObject private var loader: LazyImageLoader
    @Environment(\.dismiss) private var dismiss
    
    // Zoom state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(asset: PHAsset) {
        self.asset = asset
        _loader = StateObject(wrappedValue: LazyImageLoader(asset: asset))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let img = loader.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 1.0), 5.0) // clamp 1x to 5x
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                // Snap back if zoomed out below 1x
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                            }
                    )
                // drag to pan when zoomed in
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only allow panning when zoomed in
                                guard scale > 1.0 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                // double tap to reset zoom
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            loader.loadImage(targetSize: PHImageManagerMaximumSize)
        }
        .onDisappear {
            loader.cancel()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title2)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
