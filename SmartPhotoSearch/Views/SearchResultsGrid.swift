//
//  Views/SearchResultsGrid.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 7/4/26.
//

import SwiftUI
import Photos

/// Display search results in the same grid style as GalleryGrid
/// Shows empty state when no results match the query
struct SearchResultsGrid: View {
    let assets: [PHAsset]
    let allTags: [String: [ImageTag]]
    let uploadStatuses: [String: UploadStatus]
    
    @State private var selectedIndex: Int? = nil
    
    private let columns = 3
    private let spacing: CGFloat = 2
    
    var body: some View {
        if assets.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: spacing),
                        count: columns
                    ),
                    spacing: spacing
                ) {
                    ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                        LazyImageCell(
                            asset: asset,
                            uploadStatus: uploadStatuses[asset.localIdentifier]
                        )
                        .onTapGesture {
                            selectedIndex = index
                        }
                    }
                }
                .padding(.horizontal, spacing)
            }
            .navigationDestination(item: $selectedIndex) { index in
                PhotoDetailView(
                    assets: assets,
                    initialIndex: index,
                    tagsMap: allTags
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No photos found")
                .font(.headline)
            Text("Try searching for objects, scenes, or activities")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
