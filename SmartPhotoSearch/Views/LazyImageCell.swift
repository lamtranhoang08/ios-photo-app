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
    @StateObject private var loader: LazyImageLoader

    init(asset: PHAsset) {
        self.asset = asset
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
                    // Simple pulse animation while loading
                    Color.gray.opacity(0.2)
                        .frame(width: size, height: size)
                }
            }
            // ✅ onAppear on the CONTAINER — always fires when cell enters screen
            .onAppear {
                loader.loadImage(targetSize: targetSize)
            }
            // ✅ Cancel in-flight request when cell scrolls off screen
            .onDisappear {
                loader.cancel()
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
