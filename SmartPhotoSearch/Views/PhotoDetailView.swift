//
//  Views/PhotoDetailView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 19/3/26.
//

import SwiftUI
import Photos

/// Full-screen photo viewer with horizontal swipe navigation between photos
/// and vertical swipe-to-dismiss gesture matching Apple Photos behaviour.
struct PhotoDetailView: View {

    // MARK: - Properties
    let assets: [PHAsset]
    let initialIndex: Int
    let tagsMap: [String: [ImageTag]]

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    // Tracks vertical drag for swipe-to-dismiss
    @State private var dragOffset: CGSize = .zero

    // MARK: - Init
    init(assets: [PHAsset], initialIndex: Int, tagsMap: [String: [ImageTag]] = [:]) {
        self.assets = assets
        self.initialIndex = initialIndex
        self.tagsMap = tagsMap
        self._currentIndex = State(initialValue: initialIndex)
    }

    // MARK: - Dismiss Animations

    /// Background fades out as user drags to dismiss
    private var backgroundOpacity: Double {
        let progress = abs(dragOffset.height) / 300
        return Double(max(0.3, 1.0 - progress * 0.7))
    }

    /// View shrinks as user drags to dismiss
    private var dismissScale: CGFloat {
        let progress = abs(dragOffset.height) / 400
        return max(0.85, 1.0 - progress * 0.15)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            if !assets.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(assets.enumerated()), id: \.offset) { index, asset in
                        PhotoPageView(
                            asset: asset,
                            tags: tagsMap[asset.localIdentifier] ?? []
                        )
                        .tag(index)
                        // Apply dismiss animations to each page
                        .offset(y: dragOffset.height)
                        .scaleEffect(dismissScale)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        // Swipe-to-dismiss lives on the outer ZStack so it doesn't
        // interfere with TabView's horizontal swipe or PhotoPageView's
        // pinch/pan gestures.
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    // Only activate for clearly vertical gestures.
                    // Horizontal gestures pass through to TabView.
                    guard abs(value.translation.height) > abs(value.translation.width) * 1.5 else {
                        return
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard abs(dragOffset.height) > 0 else { return }

                    let velocity = value.predictedEndLocation.y - value.location.y
                    let shouldDismiss = abs(dragOffset.height) > 100 || velocity > 300

                    if shouldDismiss {
                        // Animate off screen then dismiss
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = CGSize(
                                width: dragOffset.width,
                                height: dragOffset.height > 0 ? 1000 : -1000
                            )
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    } else {
                        // Snap back — user didn't drag far enough
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
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
