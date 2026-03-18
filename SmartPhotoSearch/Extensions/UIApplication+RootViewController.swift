//
//  UIApplication+RootViewController.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 16/3/26.
//


import UIKit

extension UIApplication {
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
