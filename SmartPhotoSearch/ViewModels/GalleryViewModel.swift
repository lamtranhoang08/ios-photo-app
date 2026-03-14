//
//  GalleryViewModel.swift
//  SmartPhotoSearch
//
//  Created by Lâm Trần on 14/3/26.
//

import Foundation
import SwiftUI
import UIKit
import Combine

class GalleryViewModel : ObservableObject {
    @Published var photos: [UIImage] = []
    
    private let photoService = PhotoLibraryService()
    
    func loadPhotos() {
        photos = photoService.fetchPhotos(limit: 20)
    }
}
