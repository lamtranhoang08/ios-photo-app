//
//  Extensions/PHAsset+Hashable.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 19/3/26.
//

import Photos

extension PHAsset: @retroactive Hashable {
    public override var hash: Int {
        localIdentifier.hashValue
    }

    public static func == (lhs: PHAsset, rhs: PHAsset) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
}
