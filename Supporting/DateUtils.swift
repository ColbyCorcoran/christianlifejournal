//
//  DateUtils.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation

func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

