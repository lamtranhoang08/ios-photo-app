//
//  Views/PhotoDetailView.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 19/3/26.
//

import SwiftUI
import Photos

/// Full-screen photo viewer with horizontal swipe navigation between photos
/// and vertical swipe-to-dismiss gesture matching Apple Photos behaviour.
struct PhotoDetailView: View {
    
    // MARK: - Properties
    let assets: [PHAsset]
    let initialIndex: Int
    let tagsMap: [String: [ImageTag]]
    let uploadStatuses: [String: UploadStatus]
    let onUpload: ((PHAsset) -> Void)?
    let onDelete: ((PHAsset) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var showDeleteConfirmation = false
    @State private var deleteError: String? = nil
    
    // Tracks vertical drag for swipe-to-dismiss
    @State private var dragOffset: CGSize = .zero
    @State private var showInfo: Bool = false
    
    // MARK: - Init
    init(
        assets: [PHAsset],
        initialIndex: Int,
        tagsMap: [String: [ImageTag]] = [:],
        uploadStatuses: [String: UploadStatus] = [:],
        onUpload: ((PHAsset) -> Void)? = nil,
        onDelete: ((PHAsset) -> Void)? = nil
    ) {
        self.assets = assets
        self.initialIndex = initialIndex
        self.tagsMap = tagsMap
        self._currentIndex = State(initialValue: initialIndex)
        self.uploadStatuses = uploadStatuses
        self.onUpload = onUpload
        self.onDelete = onDelete
        
    }
    
    // MARK: - Dismiss Animations
    
    /// Background fades out as user drags to dismiss
    private var backgroundOpacity: Double {
        let progress = abs(dragOffset.height) / 300
        return Double(max(0.3, 1.0 - progress * 0.7))
    }
    
    /// View shrinks as user drags to dismiss
    private var dismissScale: CGFloat {
        let progress = abs(dragOffset.height) / 400
        return max(0.85, 1.0 - progress * 0.15)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            if !assets.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(assets.enumerated()), id: \.offset) { index, asset in
                        PhotoPageView(
                            asset: asset,
                            showInfo: $showInfo
                        )
                        .tag(index)
                        .offset(y: dragOffset.height)
                        .scaleEffect(dismissScale)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentIndex) { _, _ in
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85)) {
                        showInfo = false
                    }
                }
            }
            
            //info panel slides up from bottom
            if showInfo, currentIndex < assets.count {
                InfoPanel(
                    asset: assets[currentIndex],
                    tags: tagsMap[assets[currentIndex].localIdentifier] ?? [],
                    onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showInfo = false
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .confirmationDialog(
            "Delete Photo?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete from Device and SmartPhotoSearch", role: .destructive) {
                guard currentIndex < assets.count else { return }
                let asset = assets[currentIndex]
                onDelete?(asset)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the photo from your device and SmartPhotoSearch")
        }
        .alert("Delete Failed", isPresented: .init(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
        
        // Swipe-to-dismiss lives on the outer ZStack so it doesn't
        // interfere with TabView's horizontal swipe or PhotoPageView's
        // pinch/pan gestures.
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    let isVertical = abs(value.translation.height) > abs(value.translation.width) * 1.2
                    let passedThreshold = abs(value.translation.height) > 10
                    guard isVertical && passedThreshold else { return }
                    
                    guard !showInfo else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard abs(dragOffset.height) > 0 else { return }
                    
                    let velocity = value.predictedEndLocation.y - value.location.y
                    let shouldDismiss = abs(dragOffset.height) > 100 || velocity > 300
                    
                    if shouldDismiss {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = CGSize(
                                width: dragOffset.width,
                                height: dragOffset.height > 0 ? 1000 : -1000
                            )
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    } else {
                        // Snap back — user didn't drag far enough
                        withAnimation(.interactiveSpring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .safeAreaInset(edge: .bottom) {
            bottomToolbar
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title2)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    // MARK: - Bottom Toolbar
    /// Info and delete actions — always visible above home indicator.
    /// .safeAreaInset handles safe area automatically on all devices.
    private var bottomToolbar: some View {
        HStack {
            // Info
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showInfo.toggle()
                }
            } label: {
                Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            Spacer()
            
            // Upload button — only shown when asset is not yet uploaded
            if currentIndex < assets.count {
                let asset = assets[currentIndex]
                let status = uploadStatuses[asset.localIdentifier]
                
                switch status {
                case .uploading(let progress):
                    // Show progress instead of button while uploading
                    VStack(spacing: 2) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(width: 60)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                    
                case .tagging:
                    HStack(spacing: 4) {
                        ProgressView().tint(.white).scaleEffect(0.7)
                        Text("Tagging...")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                    
                case .done, .tagged:
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    
                case .failed:
                    // Allow retry on failure
                    Button {
                        onUpload?(asset)
                    } label: {
                        Image(systemName: "exclamationmark.icloud.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    
                case .pending, .none:
                    Button {
                        onUpload?(asset)
                    } label: {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
            }
            
            Spacer()
            
            // Delete (placeholder for future)
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
