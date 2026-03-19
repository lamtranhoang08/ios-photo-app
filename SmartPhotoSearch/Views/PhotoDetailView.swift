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
