//
//  Services/SearchHistoryService.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 2/5/26.
//

import Foundation

///Persists and manages recent search queries
///Stores up to 10 recent searches in UserDefaults
///Most recent searchers appear first
///Duplicate entries are deduplicated
///Re-searching move queries to top
///

class SearchHistoryService {
    // MARK: - Constant
    private let key = "Search History"
    private let maxEntries = 10
    
    // MARK: - Read
    
    // Returned store searches, most recent first
    func load() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    // MARK: - Write
    
    /// adds a query to history
    /// deduplicate and trims to maxEntries
    func add(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        var history = load()
        // Remove existing entry to avoid duplicates
        // Re-insert that duplicate at top
        history.removeAll { $0.lowercased() == trimmed.lowercased() }
        history.insert(trimmed, at: 0)
        // Trim to max
        history = Array(history.prefix(maxEntries))
        UserDefaults.standard.set(history, forKey: key)
    }
    
    /// Removes a specific query from history
    func remove(_ query: String) {
        var history = load()
        history.removeAll() { $0 == query }
        UserDefaults.standard.set(history, forKey: key)
    }
    
    /// Clears all search history
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
