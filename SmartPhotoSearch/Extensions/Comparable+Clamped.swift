//
//  Comparable+Clamped.swift
//  SmartPhotoSearch
//
//  Created by TranHoangLam on 15/3/2026.
//

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
