import Foundation
import Sparkle

final class UpdateChecker: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = true

    init() {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Set up bindings
        self.canCheckForUpdates = updaterController.updater.canCheckForUpdates
        self.automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func checkForUpdatesInBackground() {
        // Check silently in background
        updaterController.updater.checkForUpdatesInBackground()
    }
}
