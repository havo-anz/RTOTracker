import Foundation
import Sparkle

@MainActor
final class UpdateChecker: ObservableObject {
    private var updaterController: SPUStandardUpdaterController?

    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = true

    var isAvailable: Bool {
        return updaterController != nil
    }

    init() {
        // Check if we have a valid public key configured
        guard let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              !publicKey.isEmpty,
              publicKey != "PLACEHOLDER_GENERATE_KEYS_FIRST" else {
            print("⚠️ Sparkle auto-updates disabled: EdDSA keys not generated yet")
            print("💡 Run: cd ~/Library/Developer/Xcode/DerivedData/RTOTracker-*/SourcePackages/checkouts/Sparkle/ && ./bin/generate_keys")
            return
        }

        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Set up bindings
        self.canCheckForUpdates = updaterController?.updater.canCheckForUpdates ?? false
        self.automaticallyChecksForUpdates = updaterController?.updater.automaticallyChecksForUpdates ?? false
    }

    func checkForUpdates() {
        guard let updaterController = updaterController else {
            print("⚠️ Cannot check for updates: Sparkle not initialized (keys not generated)")
            return
        }
        updaterController.checkForUpdates(nil)
    }

    func checkForUpdatesInBackground() {
        guard let updaterController = updaterController else {
            return
        }
        // Check silently in background
        updaterController.updater.checkForUpdatesInBackground()
    }
}
