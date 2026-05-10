import Foundation
import SwiftUI

@MainActor
final class EditSessionModel: ObservableObject {
    @Published private var recipesByFileID: [String: EditRecipe] = [:]
    private var loadedRecipesByFileID: [String: EditRecipe] = [:]
    private var persistenceTasksByFileID: [String: Task<Void, Never>] = [:]
    private var persistenceTokensByFileID: [String: UUID] = [:]
    private let sidecarStore: EditRecipeSidecarStore
    private let coalescedPersistenceDelayNanoseconds: UInt64

    init(
        sidecarStore: EditRecipeSidecarStore = EditRecipeSidecarStore(),
        coalescedPersistenceDelayNanoseconds: UInt64 = 250_000_000
    ) {
        self.sidecarStore = sidecarStore
        self.coalescedPersistenceDelayNanoseconds = coalescedPersistenceDelayNanoseconds
    }

    func recipe(for file: LocalImageFile?) -> EditRecipe {
        guard let file else {
            return .neutral
        }

        if let recipe = recipesByFileID[file.id] {
            return recipe
        }

        if let recipe = loadedRecipesByFileID[file.id] {
            return recipe
        }

        do {
            let recipe = try sidecarStore.loadRecipe(for: file.url) ?? .neutral
            loadedRecipesByFileID[file.id] = recipe
            return recipe
        } catch {
            NSLog("DarkRoom could not load edit sidecar for %@: %@", file.url.path, String(describing: error))
            loadedRecipesByFileID[file.id] = .neutral
            return .neutral
        }
    }

    func binding(for file: LocalImageFile?) -> Binding<EditRecipe> {
        Binding(
            get: { [weak self] in
                self?.recipe(for: file) ?? .neutral
            },
            set: { [weak self] nextRecipe in
                self?.setRecipe(nextRecipe, for: file)
            }
        )
    }

    func reset(file: LocalImageFile?) {
        setRecipe(.neutral, for: file, persistenceDelayNanoseconds: 0)
    }

    func flushPendingPersistence(for file: LocalImageFile?) async {
        guard let request = persistenceRequest(for: file) else {
            return
        }

        let task = schedulePersistence(
            request,
            delayNanoseconds: 0
        )
        await task.value
    }

    private func setRecipe(
        _ recipe: EditRecipe,
        for file: LocalImageFile?,
        persistenceDelayNanoseconds: UInt64? = nil
    ) {
        guard let file else {
            return
        }

        if recipe.isNeutral {
            recipesByFileID.removeValue(forKey: file.id)
            loadedRecipesByFileID[file.id] = .neutral
        } else {
            recipesByFileID[file.id] = recipe
            loadedRecipesByFileID[file.id] = recipe
        }

        let request = RecipePersistenceRequest(
            fileID: file.id,
            sourceURL: file.url,
            recipe: recipe
        )
        schedulePersistence(
            request,
            delayNanoseconds: persistenceDelayNanoseconds ?? coalescedPersistenceDelayNanoseconds
        )
    }

    private func persistenceRequest(for file: LocalImageFile?) -> RecipePersistenceRequest? {
        guard let file else {
            return nil
        }

        return RecipePersistenceRequest(
            fileID: file.id,
            sourceURL: file.url,
            recipe: recipe(for: file)
        )
    }

    @discardableResult
    private func schedulePersistence(
        _ request: RecipePersistenceRequest,
        delayNanoseconds: UInt64
    ) -> Task<Void, Never> {
        persistenceTasksByFileID[request.fileID]?.cancel()

        let token = UUID()
        persistenceTokensByFileID[request.fileID] = token
        let sidecarStore = sidecarStore

        let task = Task.detached(priority: .utility) {
            if delayNanoseconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else {
                return
            }

            do {
                try sidecarStore.save(request.recipe, for: request.sourceURL)
            } catch {
                NSLog("DarkRoom could not save edit sidecar for %@: %@", request.sourceURL.path, String(describing: error))
            }
        }

        persistenceTasksByFileID[request.fileID] = task

        Task { @MainActor [weak self] in
            await task.value
            guard self?.persistenceTokensByFileID[request.fileID] == token else {
                return
            }

            self?.persistenceTasksByFileID[request.fileID] = nil
            self?.persistenceTokensByFileID[request.fileID] = nil
        }

        return task
    }
}

private struct RecipePersistenceRequest: Sendable {
    let fileID: String
    let sourceURL: URL
    let recipe: EditRecipe
}
