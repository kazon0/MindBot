//
//  ResourceViewModel.swift
//  PhiAI
//

import Foundation

class ResourceViewModel: ObservableObject {
    @Published var resources: [Resource] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @MainActor
    func loadResources() async {
        isLoading = true
        do {
            let data = try await APIManager.shared.fetchResources()
            self.resources = data
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

