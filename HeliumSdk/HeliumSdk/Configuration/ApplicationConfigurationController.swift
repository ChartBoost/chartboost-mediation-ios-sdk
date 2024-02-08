// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The source of a `ApplicationConfiguration`.
enum ApplicationConfigurationSource: CaseIterable {
    /// Fetched from the backend.
    case backend

    /// Hardcoded default values defined in source code.
    case hardcodedDefault

    /// Loaded from previously cached data in local storage.
    case localCache
}

typealias UpdateAppConfigCompletion = (_ appConfigSource: ApplicationConfigurationSource, _ error: ChartboostMediationError?) -> Void

/// Manages the app-specific configuration for the Helium SDK.
protocol ApplicationConfigurationController {
    /// Fetches a new configuration from backend.
    func updateConfiguration(completion: @escaping UpdateAppConfigCompletion)
}

/// A configuration controller that updates the configuration using data fetched from backend and persists it across app sessions.
final class PersistingApplicationConfigurationController: ApplicationConfigurationController {
    @Injected(\.appConfiguration) private var configuration
    @Injected(\.fileStorage) private var fileStorage
    @Injected(\.userDefaultsStorage) private var defaultsStorage
    @Injected(\.appConfigurationService) private var service

    private var initHash: String? {
        get { defaultsStorage["init-hash"] }
        set { defaultsStorage["init-hash"] = newValue }
    }

    init() {
        // Tries to restore a persisted configuration from a previous session
        restorePersistedConfiguration()
    }

    private var appConfigSource: ApplicationConfigurationSource = .hardcodedDefault

    /// The file system url where the configuration data is stored.
    private var heliumConfigURL: URL {
        get throws {
            try fileStorage.urlForHeliumConfigurationDirectory.appendingPathComponent("HeConfig.json")
        }
    }

    /// Obtains new configuration data from backend and updates the `configuration` property with it.
    /// It also persists new configuration in disk to reuse in the next session.
    func updateConfiguration(completion: @escaping UpdateAppConfigCompletion) {
        logger.debug("App config update started")

        // Fetch new data from backend
        service.fetchAppConfiguration(sdkInitHash: initHash) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let update):
                guard let update else {
                    logger.debug("App config update succeeded with no new data")
                    completion(self.appConfigSource, nil)
                    return
                }

                do {
                    try self.updateConfiguration(with: update.data)
                    self.appConfigSource = .backend
                    self.initHash = update.sdkInitHash
                    logger.debug("App config update succeeded with new data")
                    completion(self.appConfigSource, nil)
                } catch {
                    logger.error("Failed to parse app config with error \(error)")
                    let chartboostMediationError = error as? ChartboostMediationError
                        ?? .init(code: .initializationFailureInternalError, error: error, data: update.data)
                    completion(self.appConfigSource, chartboostMediationError)
                }

            case .failure(let error):
                logger.error("App config update failed with error: \(error)")
                completion(self.appConfigSource, error)
            }
        }
    }

    /// Updates the configuration using the persisted data from a previous session, if available.
    private func restorePersistedConfiguration() {
        let url: URL
        do {
            url = try heliumConfigURL
        } catch {
            logger.error("Failed to compute app config URL with error \(error)")
            return
        }

        func removeCorruptedData() {
            do {
                initHash = nil
                try fileStorage.removeFile(at: url)
                logger.warning("Removed corrupted app config")
            } catch {
                logger.error("Failed to remove persisted app config with error \(error)")
            }
        }

        guard fileStorage.fileExists(at: url) else {
            initHash = nil
            logger.debug("No persisted app config found, will use default values")
            return
        }

        let data: Data
        do {
            data = try fileStorage.readData(at: url)
        } catch {
            logger.error("Failed to read persisted app config with error \(error)")
            removeCorruptedData()
            return
        }

        do {
            try configuration.update(with: data)
            appConfigSource = .localCache
            logger.debug("Restored persisted app config")
        } catch {
            logger.error("Failed to update persisted app config with error \(error)")
            removeCorruptedData()
            return
        }
    }

    /// Updates the configuration with a JSON-encoded data from the backend, and persists the data so it is available
    /// right away on the next session.
    private func updateConfiguration(with data: Data) throws {
        // Update configuration
        try configuration.update(with: data)
        // Persist data to use in the next session
        do {
            try fileStorage.write(data, to: heliumConfigURL)
            logger.debug("Persisted new app config")
        } catch {
            logger.error("Failed to persist app config with error \(error)")
        }
    }
}
