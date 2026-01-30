//
//  IntegratedScreenView.swift
//  HackathonApp
//
//  Replace this file with your single-screen view from the other project,
//  or add your view as a new tab in HackathonAppApp.swift and remove this placeholder.
//

import SwiftUI

struct IntegratedScreenView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Your integrated screen")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Replace this view with your screen:\ncopy your view file into Views/ and use it in the TabView in HackathonAppApp.swift")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Integrated")
        }
    }
}

#Preview {
    IntegratedScreenView()
}
