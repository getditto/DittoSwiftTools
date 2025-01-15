//
//  FormViewModel.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI

/// Manages the state and logic for the identity form.
///
/// `FormViewModel` is responsible for:
/// - Populating the form with existing credentials.
/// - Validating and applying form data.
/// - Clearing active credentials and managing error states.
class FormViewModel: ObservableObject {

    /// Holds the current state of the form, including user inputs.
    @Published var formState = FormState()

    /// Tracks validation errors for the form.
    @Published var validationErrors: [String] = []

    /// Service for managing credentials.
    private let credentialsService: CredentialsService

    /// Service for interacting with Ditto.
    private let dittoService: DittoService

    // MARK: - Initializer

    /// Initializes the view model and populates the form with active credentials, if available.
    ///
    /// - Parameters:
    ///   - credentialsService: The service responsible for managing credentials.
    ///   - dittoService: The service responsible for initializing and managing Ditto.
    init(credentialsService: CredentialsService, dittoService: DittoService) {
        self.credentialsService = credentialsService
        self.dittoService = dittoService

        // Check for an active configuration
        if let credentials = credentialsService.activeCredentials {
            populate(with: credentials)
        }
    }

    // MARK: - Public Methods

    /// Validates and applies the form data to initialize Ditto.
    ///
    /// Throws an error if validation fails or Ditto initialization fails.
    func apply() throws {
        do {
            let credentials = try createCredentials()
            try dittoService.initializeDitto(with: credentials)
            validationErrors = []
        } catch {
            handleError(error)
            throw error
        }
    }

    /// Checks if credentials can be cleared.
    ///
    /// - Returns: `true` if there are active credentials to clear; otherwise, `false`.
    func canClearCredentials() -> Bool {
        credentialsService.activeCredentials != nil
    }

    /// Clears the active credentials and resets the form state.
    func clearCredentials() {
        dittoService.destroyDittoInstance(clearingCredentials: true)
        self.formState = FormState()
        print("CredentialsView: Credentials cleared.")
    }

    // MARK: - Private Methods

    /// Populates the form state with the given credentials.
    ///
    /// - Parameter credentials: The credentials to populate the form with.
    private func populate(with credentials: Credentials) {
        formState.identityType = credentials.identity.identityType

        switch credentials.identity {
        case .onlinePlayground(let appID, let token, let enableDittoCloudSync, let customAuthURL):
            formState.appID = appID
            formState.playgroundToken = token
            formState.enableDittoCloudSync = enableDittoCloudSync
            formState.customAuthURLString = customAuthURL?.absoluteString ?? ""

        case .onlineWithAuthentication(let appID, _, let enableDittoCloudSync, let customAuthURL):
            formState.appID = appID
            formState.enableDittoCloudSync = enableDittoCloudSync
            formState.customAuthURLString = customAuthURL?.absoluteString ?? ""
            formState.authProvider = credentials.authProvider ?? ""
            formState.authToken = credentials.authToken ?? ""

        case .offlinePlayground(let appID, let siteID):
            formState.appID = appID ?? ""
            formState.siteID = siteID ?? .zero
            formState.offlineLicenseToken = credentials.offlineLicenseToken ?? ""

        case .sharedKey(let appID, let sharedKey, let siteID):
            formState.appID = appID
            formState.sharedKey = sharedKey
            formState.siteID = siteID ?? .zero
            formState.offlineLicenseToken = credentials.offlineLicenseToken ?? ""

        case .manual(let certificateConfig):
            formState.certificateConfig = certificateConfig

        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }

    /// Creates a `Credentials` object from the form state.
    ///
    /// This utility method generates an `Credentials` instance based on the values
    /// entered in the form. It creates the appropriate `DittoIdentity` based on the selected identity type,
    /// and adds any necessary supplementary credentials such as authentication tokens or offline license tokens.
    ///
    /// - Throws: `DittoServiceError.invalidCredentials` if validation fails or the identity type is unsupported.
    /// - Returns: A fully configured `Credentials` object.
    private func createCredentials() throws -> Credentials {
        // Validate the form values before attempting creation
        let validationErrors = formState.validate()
        guard validationErrors.isEmpty else {
            self.validationErrors = validationErrors
            throw DittoServiceError.invalidCredentials("Validation failed: \(validationErrors.joined(separator: ", "))")
        }

        // Map formInput data to a DittoIdentity
        let identity: DittoIdentity
        switch formState.identityType {
        case .offlinePlayground:
            identity = .offlinePlayground(
                appID: formState.appID,
                siteID: formState.siteID
            )
        case .onlineWithAuthentication:
            identity = .onlineWithAuthentication(
                appID: formState.appID,
                authenticationDelegate: credentialsService.authenticationDelegate,
                enableDittoCloudSync: formState.enableDittoCloudSync,
                customAuthURL: URL(string: formState.customAuthURLString) ?? nil
            )
        case .onlinePlayground:
            identity = .onlinePlayground(
                appID: formState.appID,
                token: formState.playgroundToken,
                enableDittoCloudSync: formState.enableDittoCloudSync,
                customAuthURL: URL(string: formState.customAuthURLString)
            )
        case .sharedKey:
            identity = .sharedKey(
                appID: formState.appID,
                sharedKey: formState.sharedKey,
                siteID: formState.siteID
            )
        case .manual:
            identity = .manual(certificateConfig: formState.certificateConfig)
        @unknown default:
            throw DittoServiceError.invalidCredentials("Unsupported or unknown Ditto Identity type encountered.")
        }

        // Create and return Credentials
        return Credentials(
            identity: identity,
            authProvider: formState.authProvider,
            authToken: formState.authToken,
            offlineLicenseToken: formState.offlineLicenseToken)
    }

    /// Handles errors during validation or Ditto initialization.
    ///
    /// - Parameter error: The error to process and store in `validationErrors`.
    private func handleError(_ error: Error) {
        if let dittoError = error as? DittoServiceError {
            switch dittoError {
            case .invalidCredentials(let message):
                validationErrors = ["Invalid credentials: \(message)"]
            case .initializationFailed(let reason):
                validationErrors = ["Ditto initialization failed: \(reason)"]
            case .syncFailed(let reason):
                validationErrors = ["Failed to start the sync engine: \(reason)"]
            default:
                validationErrors = ["An unknown error occurred."]
            }
        } else {
            validationErrors = ["An unexpected error occurred: \(error.localizedDescription)"]
        }
    }
}
