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
    let tags: [ImageTag]
    @StateObject private var loader: LazyImageLoader
    @Environment(\.dismiss) private var dismiss
    
    // Zoom state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(asset: PHAsset, tags:[ImageTag]) {
        self.asset = asset
        self.tags = tags
        _loader = StateObject(wrappedValue: LazyImageLoader(asset: asset))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let img = loader.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geo.size.width,
                            height: geo.size.height
                        )
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
                                    let maxX = (geo.size.width * (scale - 1)) / 2
                                    let maxY = (geo.size.height * (scale - 1)) / 2
                                    withAnimation(.spring()) {
                                        offset = CGSize(
                                            width: min(max(offset.width, -maxX), maxX),
                                            height: min(max(offset.height, -maxY), maxY)
                                        )
                                        lastOffset = offset
                                    }
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
                        .frame(
                            width: geo.size.width,
                            height: geo.size.height
                        )
                }
                
                if !tags.isEmpty {
                    VStack {
                        Spacer()
                        tagsView
                    }
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )
                }
            }
            .frame(
                width: geo.size.width,
                height: geo.size.height
            )
        }
        .ignoresSafeArea()
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
    
    // Scrollable tag chips
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
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
