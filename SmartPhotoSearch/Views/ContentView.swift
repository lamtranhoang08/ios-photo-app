//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: GalleryViewModel = .init()
    @StateObject private var searchViewModel: SearchViewModel
    @State private var isPresentingLimitedPicker: Bool = false
    
    init() {
        let galleryVM = GalleryViewModel()
        _viewModel = StateObject(wrappedValue: galleryVM)
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(assets: galleryVM.$assets, tags: galleryVM.$tags))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchViewModel.query, isSearching: $searchViewModel.isSearching)
                
                LimitedAccessBanner(
                    viewModel: viewModel,
                    isPresentingLimitedPicker: $isPresentingLimitedPicker
                )
                
                // Switch between grid and search results
                if searchViewModel.isSearching && !searchViewModel.query.isEmpty {
                    SearchResultsGrid(
                        assets: searchViewModel.results,
                        allTags: viewModel.tags,
                        uploadStatuses: viewModel.uploadStatuses
                    )
                } else {
                    GalleryGrid(viewModel: viewModel)
                }
            }
            .navigationTitle("SmartPhotoSearch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                GalleryToolbar(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadPhotos()
            }
            .overlay {
                if viewModel.permissionDenied {
                    PermissionDeniedView()
                }
            }
            .background {
                LimitedPickerPresenter(isPresenting: $isPresentingLimitedPicker)
                    .frame(width: 0, height: 0)
            }
        }
    }
}

#Preview {
    ContentView()
}

