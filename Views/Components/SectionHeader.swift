// SectionHeader.swift
import SwiftUI

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .padding(.top, 15)
            .padding(.bottom, 5)
    }
}
