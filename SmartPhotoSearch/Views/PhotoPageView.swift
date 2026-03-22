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
    let tags: [ImageTag]

    @StateObject private var loader: LazyImageLoader

    // MARK: - Zoom State
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - Init
    init(asset: PHAsset, tags: [ImageTag] = []) {
        self.asset = asset
        self.tags = tags
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
                        // Pinch to zoom — uses simultaneousGesture so TabView
                        // swipe is not blocked
                        .simultaneousGesture(pinchGesture)
                        // Double tap — toggles between 1x and 2.5x zoom
                        .onTapGesture(count: 2) { handleDoubleTap() }
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
            // Tags pinned to bottom via overlay — always visible
            // regardless of image aspect ratio
            .overlay(alignment: .bottom) {
                if !tags.isEmpty {
                    tagsView
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Request original resolution — supports 4K/HDR assets
            loader.loadImage(targetSize: PHImageManagerMaximumSize)
        }
        .onDisappear {
            loader.cancel()
            resetZoom()
        }
    }

    // MARK: - Tag Chips
    @ViewBuilder
    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags) { tag in
                    Text(tag.displayText)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.7))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        // Use UIKit safe area — reliable regardless of ignoresSafeArea context
        .padding(.bottom, UIApplication.safeAreaBottom > 0
                 ? UIApplication.safeAreaBottom
                 : 16)
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
