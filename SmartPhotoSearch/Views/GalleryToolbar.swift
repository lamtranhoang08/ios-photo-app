//
//  Views/GalleryToolbar.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 18/3/26.
//

import SwiftUI

/// Context-sensitive toolbar for the gallery.
///
/// Normal mode:    [Tag All] [Upload All]
/// Selection mode: [Cancel]  [Upload (n)]
///
/// Designed as a ToolbarContent so it can be injected
/// via .toolbar {} without polluting ContentView's body.
struct GalleryToolbar: ToolbarContent {
    
    // MARK: - Dependencies
    @ObservedObject var viewModel: GalleryViewModel
    var onDeleteSelected: (() -> Void)? = nil
    
    // MARK: - Body
    var body: some ToolbarContent {
        leadingItem
        trailingItem
    }
    
    // MARK: - Leading
    
    /// Cancel button — only visible in selection mode.
    /// Clears selection and exits multi-select.
    private var leadingItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if viewModel.isSelectionMode {
                Button("Cancel") {
                    viewModel.toggleSelectionMode()
                }
            }
        }
    }
    
    // MARK: - Trailing
    
    /// Context-sensitive right side:
    /// - Selection mode: Upload selected photos (disabled when nothing selected)
    /// - Normal mode: Tag All + Upload All
    private var trailingItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isSelectionMode {
                selectionModeButtons
            } else {
                normalModeButtons
            }
        }
    }
        
    private var selectionModeButtons: some View {
        HStack(spacing: 16) {
            // Upload selected
            Button {
                viewModel.uploadSelected()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Upload (\(viewModel.selectedAssetIDs.count))")
                        .font(.footnote.bold())
                }
            }
            .disabled(viewModel.selectedAssetIDs.isEmpty)
            
            // Delete selected
            Button(role: .destructive) {
                onDeleteSelected?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Delete (\(viewModel.selectedAssetIDs.count))")
                        .font(.footnote.bold())
                }
            }
            .disabled(viewModel.selectedAssetIDs.isEmpty)
        }
    }
    
    /// Tag All and Upload All buttons shown in normal browsing mode.
    /// Tag All triggers on-device Vision classification for untagged assets.
    /// Upload All skips already-uploaded assets automatically.
    private var normalModeButtons: some View {
        HStack {
            Button {
                viewModel.tagAll()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                    Text("Tag All")
                        .font(.footnote.bold())
                }
            }
            
            Button {
                viewModel.uploadAll()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Upload All")
                        .font(.footnote.bold())
                }
            }
        }
    }
}
