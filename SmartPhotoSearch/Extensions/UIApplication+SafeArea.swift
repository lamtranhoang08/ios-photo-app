//
//  UIApplication+SafeArea.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 22/3/26.
//

import UIKit

extension UIApplication {
    static var safeAreaBottom: CGFloat {
        UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }
}
