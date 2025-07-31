//
//  FilterButton.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/30/25.
//

import SwiftUI

struct FilterButton<T: Hashable>: View {
    let label: String
    let selected: Set<T>
    let options: [T]
    let displayName: (T) -> String
    let onSelect: (T) -> Void

    var body: some View {
        Menu {
            ForEach(options.reversed(), id: \.self) { option in
                Button(action: { onSelect(option) }) {
                    HStack {
                        Text(displayName(option))
                        if selected.contains(option) {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.appGreenDark)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .fontWeight(selected.isEmpty ? .regular : .semibold)
                    .foregroundColor(selected.isEmpty ? .primary : .appGreenDark)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected.isEmpty ? Color.appGreenPale : Color.appGreenLight)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

