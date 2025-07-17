//
//  Utilities.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/16/25.

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
        set {
            if let newValue = newValue, indices.contains(index) {
                self[index] = newValue
            }
        }
    }
}

