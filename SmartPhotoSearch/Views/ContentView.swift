//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GalleryViewModel()
    
    let columnsCount = 3
    let spacing: CGFloat = 2
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnsCount),
                spacing: spacing
            ) {
                ForEach(viewModel.photos.indices, id: \.self) { index in
                    GeometryReader { geo in
                        let cellSize = geo.size.width
                        Image(uiImage: viewModel.photos[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: cellSize, height: cellSize)
                            .clipped()
                    }
                    .aspectRatio(1, contentMode: .fit) // keeps square cells
                }
            }
            .padding(.horizontal, spacing)
        }
        .onAppear {
            viewModel.loadPhotos()
        }
    }
}

#Preview {
    ContentView()
}
