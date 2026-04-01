//
//  Views/InfoPanel.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 1/4/26.
//

import SwiftUI
import Photos

struct InfoPanel: View {
    
    // MARK: - Properties
    let asset: PHAsset
    let tags: [ImageTag]
    let onDismiss: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Drag pill
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 36, height: 4)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            
            // MARK: Metadata rows
            VStack(alignment: .leading, spacing: 16) {
                
                // Date
                if let date = asset.creationDate {
                    InfoRow(
                        icon: "calendar",
                        title: "Date",
                        value: date.formatted(date: .long, time: .shortened)
                    )
                }
                
                // Camera model (if available)
                InfoRow(
                    icon: "camera",
                    title: "Captured with",
                    value: UIDevice.current.model
                )
                
                // Dimensions
                InfoRow(
                    icon: "photo",
                    title: "Dimensions",
                    value: "\(asset.pixelWidth) × \(asset.pixelHeight)"
                )
                
                // Tags
                if !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tags", systemImage: "tag")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags) { tag in
                                    Text(tag.displayText)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.7))
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                // Background extends into safe area — content doesn't
                .ignoresSafeArea(edges: .bottom)
        )
        // Swipe down to dismiss
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 50 { onDismiss() }
                }
        )
    }
}


// MARK: - InfoRow

/// A single metadata row with icon, title, and value.
private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}
