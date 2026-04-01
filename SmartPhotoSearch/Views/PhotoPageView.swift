//
//  Views/PhotoPageView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 21/3/26.
//

import SwiftUI
import Photos

/// A single full-screen photo page with zoom, pan, and swipe-to-dismiss support.
/// Designed to be hosted inside a TabView for horizontal photo navigation.
struct PhotoPageView: View {
    
    // MARK: - Properties
    let asset: PHAsset
    @Binding var showInfo: Bool
    
    @StateObject private var loader: LazyImageLoader
    
    // MARK: - Zoom State and Control metadata panel visibility
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    
    // MARK: - Init
    init(asset: PHAsset, showInfo: Binding<Bool>) {
        self.asset = asset
        self._showInfo = showInfo
        _loader = StateObject(wrappedValue: LazyImageLoader(asset: asset))
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let img = loader.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .simultaneousGesture(pinchGesture)
                        // Double tap — zoom toggle
                        .onTapGesture(count: 2) { handleDoubleTap() }
                        // Single tap — toggle info panel
                        .onTapGesture(count: 1) {
                            guard scale == 1.0 else { return }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showInfo.toggle()
                            }
                        }
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // Pan gesture lives on ZStack container, not the Image.
            // When scale == 1.0, gesture is nil so TabView receives
            // horizontal swipes freely. When zoomed, pan is active.
            .gesture(
                scale > 1.0
                ? AnyGesture(panGesture(geo: geo))
                : nil
            )
        }
        .onAppear {
            // Request original resolution — supports 4K/HDR assets
            loader.loadImage(targetSize: PHImageManagerMaximumSize)
        }
        .onDisappear {
            loader.cancel()
            resetZoom()
        }
    }
    
    // MARK: - Gestures
    
    /// Pinch to zoom between 1x and 5x.
    /// Uses simultaneousGesture so it doesn't block TabView's swipe.
    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.0 {
                    withAnimation(.spring()) { resetZoom() }
                }
            }
    }
    
    /// Pan gesture — only active when zoomed in (scale > 1.0).
    /// Clamps offset so image never drifts fully off screen.
    private func panGesture(geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                let maxX = (geo.size.width * (scale - 1)) / 2
                let maxY = (geo.size.height * (scale - 1)) / 2
                withAnimation(.spring()) {
                    offset = CGSize(
                        width: min(max(offset.width, -maxX), maxX),
                        height: min(max(offset.height, -maxY), maxY)
                    )
                }
                lastOffset = offset
            }
    }
    
    // MARK: - Helpers
    
    /// Double tap toggles between 1x and 2.5x zoom.
    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if scale > 1.0 {
                resetZoom()
            } else {
                scale = 2.5
            }
        }
    }
    
    /// Resets all zoom and pan state to default.
    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
}
