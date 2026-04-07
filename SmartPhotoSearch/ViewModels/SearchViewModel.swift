//
//  ViewModels/SearchViewModel.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 6/4/26.
//

import Foundation
import Combine
import Photos

/// Drives the search experience.
///
/// Accept a raw query string, debounces input to avoid seaching on every keystroke
/// tokenise the query and matches tokens against in-memory tags
///
/// All matching happens locally
/// Tags must be loaded into GalleryViewModel.tags before executing searching

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Properties
    @Published var query: String = ""
    @Published var results: [PHAsset] = []
    @Published var isSearching: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(assets: Published<[PHAsset]>.Publisher,
         tags: Published<[String: [ImageTag]]>.Publisher) {
        
        // Combine latest assets + tags + query
        // Debounce query to avoid searching on every keystroke
        Publishers.CombineLatest3(
            assets,
            tags,
            $query.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        )
        .map { assets, tags, query in
            Self.search(query: query, in: assets, tags: tags)
        }
        .assign(to: &$results)
    }
    
    // MARK: - Search Logic
    
    /// Tokenizes the query and matches against asset tags.
    /// Ranking: assets matching more tokens rank higher.
    /// Empty query returns all assets.
    private static func search(
        query: String,
        in assets: [PHAsset],
        tags: [String: [ImageTag]]
    ) -> [PHAsset] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return assets }
        
        // Tokenize — split on spaces, lowercase, remove empty
        let tokens = trimmed
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        // Score each asset by how many tokens match its tags
        let scored: [(asset: PHAsset, score: Int)] = assets.compactMap { asset in
            let assetTags = tags[asset.localIdentifier]?.map { $0.identifier.lowercased() } ?? []
            guard !assetTags.isEmpty else { return nil }
            
            let score = tokens.filter { token in
                assetTags.contains { tag in tag.contains(token) }
            }.count
            
            guard score > 0 else { return nil }
            return (asset, score)
        }
        
        // Sort by score descending — best matches first
        return scored
            .sorted { $0.score > $1.score }
            .map { $0.asset }
    }
}
