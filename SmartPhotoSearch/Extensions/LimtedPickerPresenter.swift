//
//  Extensions/LimtedPickerPresenter.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//
import SwiftUI
import PhotosUI

struct LimitedPickerPresenter: UIViewControllerRepresentable {
    @Binding var isPresenting: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresenting else { return }
        guard uiViewController.presentedViewController == nil else { return }

        // Fall back to Settings for now — revisit when iOS 26 is stable
        // Dispatch to next run loop to avoid modifying state during view update
        DispatchQueue.main.async {
            if #available(iOS 26, *) {
                self.isPresenting = false
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } else {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: uiViewController)
                self.isPresenting = false
            }
        }
    }
}
