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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(selected.isEmpty ? .secondary : .appGreenDark)
                
                // Always reserve space for count badge to prevent layout shifts
                HStack(spacing: 2) {
                    if !selected.isEmpty {
                        Text("\(selected.count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(
                                Circle()
                                    .fill(Color.appGreenDark)
                            )
                    } else {
                        // Invisible spacer to maintain consistent spacing
                        Text("0")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.clear)
                            .frame(minWidth: 16, minHeight: 16)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(selected.isEmpty ? .secondary : .appGreenDark)
                }
            }
            .frame(maxWidth: .infinity) // Fill available space equally
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected.isEmpty ? Color.gray.opacity(0.3) : Color.appGreenDark.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selected.isEmpty ? Color.gray.opacity(0.05) : Color.appGreenLight.opacity(0.1))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

