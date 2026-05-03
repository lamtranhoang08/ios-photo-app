//
//  Views/SearchHistoryView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 3/5/26.
//

import SwiftUI

/// Shows recent searches when search bar is focused but query is empty
/// Matches Apple's native search history pattern
struct SearchHistoryView: View {
    
    let history: [String]
    let onSelect: (String) -> Void
    let onDelete: (String) -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        if history.isEmpty {
            emptyState
        } else {
            List {
                Section {
                    ForEach(history, id: \.self) { query in
                        Button {
                            onSelect(query)
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                
                                Text(query)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDelete(query)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Searches")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: onClearAll) {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                        .textCase(nil)
                        .padding(.bottom, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No recent searches")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
