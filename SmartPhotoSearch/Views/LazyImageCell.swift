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
    @StateObject private var loader: LazyImageLoader

    init(asset: PHAsset, uploadStatus: UploadStatus? = nil) {
        self.asset = asset
        self.uploadStatus = uploadStatus
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
                uploadOverlay(size: size)
            }
            // always fires when cell enters screen
            .onAppear {
                loader.loadImage(targetSize: targetSize)
            }
            // Cancel in-flight request when cell scrolls off screen
            .onDisappear {
                loader.cancel()
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
