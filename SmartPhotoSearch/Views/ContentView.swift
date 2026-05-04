//
//  ContentView.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 13/3/26.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = GalleryViewModel()
    // Don't init SearchViewModel here — create it in a wrapper
    
    var body: some View {
        GalleryCoordinatorView(viewModel: viewModel)
    }
}

// Separate view owns SearchViewModel so it has access to viewModel's publishers
struct GalleryCoordinatorView: View {
    @ObservedObject var viewModel: GalleryViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @State private var isPresentingLimitedPicker = false
    @State private var showDeleteConfirmation = false

    init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(
            assets: viewModel.$assets,
            tags: viewModel.$tags
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(
                    text: $searchViewModel.query,
                    isSearching: $searchViewModel.isSearching,
                    onCommit: { query in searchViewModel.commitSearch(query) }
                )
                LimitedAccessBanner(
                    viewModel: viewModel,
                    isPresentingLimitedPicker: $isPresentingLimitedPicker
                )
                ZStack {
                    GalleryGrid(viewModel: viewModel, showDeleteConfirmation: $showDeleteConfirmation)
                    if searchViewModel.isSearching {
                        Color(.systemBackground).ignoresSafeArea()
                        if searchViewModel.query.isEmpty {
                            SearchHistoryView(
                                history: searchViewModel.history,
                                onSelect: { query in
                                    searchViewModel.query = query
                                    searchViewModel.commitSearch(query)
                                },
                                onDelete: { searchViewModel.removeHistory($0) },
                                onClearAll: { searchViewModel.clearHistory() }
                            )
                        } else {
                            SearchResultsGrid(
                                assets: searchViewModel.results,
                                allTags: viewModel.tags,
                                uploadStatuses: viewModel.uploadStatuses
                            )
                        }
                    }
                }
            }
            .navigationTitle("SmartPhotoSearch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { GalleryToolbar(viewModel: viewModel)
                {
                    showDeleteConfirmation = true
                }
            }
            .onAppear { viewModel.loadPhotos() }
            .overlay {
                if viewModel.permissionDenied { PermissionDeniedView() }
            }
            .background {
                LimitedPickerPresenter(isPresenting: $isPresentingLimitedPicker)
                    .frame(width: 0, height: 0)
            }
        }
    }
}
