//
//  Views/SearchBar.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 7/4/26.
//

import SwiftUI

/// Reusable search bar with cancel button
/// Mirrors the native iOS search bar style

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    var placeholder: String = "Search photos..."
    var onCommit: ((String) -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        isFocused = false
                        onCommit?(text) // Save to history on commit
                    }
                
                // Clear button
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            
            // Cancel button — only shown when searching
            if isSearching {
                Button("Cancel") {
                    text = ""
                    isSearching = false
                    isFocused = false
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
        .onChange(of: isFocused) { _, focused in
            if focused { isSearching = focused }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
