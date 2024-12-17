//
//  FormViewModel.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import DittoSwift
import SwiftUI

class FormViewModel: ObservableObject {
    // Form fields grouped into a struct
    @Published var formInput: IdentityFormInput

    // Validation errors for the form
    @Published var validationErrors: [String] = []

    private let credentialsService: CredentialsService
    private let dittoService: DittoService

    // Initializer that automatically adopts active configuration if available
    init(credentialsService: CredentialsService, dittoService: DittoService) {
        self.credentialsService = credentialsService
        self.dittoService = dittoService

        // Initialize formInput with default values
        self.formInput = IdentityFormInput()

        // Check for an active configuration in the service
        if let credentials = credentialsService.activeCredentials {
            populateFromCredentials(credentials)
        }
    }

    /// Populate the ViewModel fields from an Credentials
    private func populateFromCredentials(_ credentials: Credentials) {
        formInput.identityType = credentials.identity.identityType

        switch credentials.identity {
        case .onlinePlayground(let appID, let token, let enableDittoCloudSync, let customAuthURL):
            formInput.appID = appID
            formInput.playgroundToken = token
            formInput.enableDittoCloudSync = enableDittoCloudSync
            formInput.customAuthURLString = customAuthURL?.absoluteString ?? ""

        case .onlineWithAuthentication(let appID, _, let enableDittoCloudSync, let customAuthURL):
            formInput.appID = appID
            formInput.enableDittoCloudSync = enableDittoCloudSync
            formInput.customAuthURLString = customAuthURL?.absoluteString ?? ""
            formInput.authProvider = credentials.supplementaryCredentials.authProvider ?? ""
            formInput.authToken = credentials.supplementaryCredentials.authToken ?? ""

        case .offlinePlayground(let appID, let siteID):
            formInput.appID = appID ?? ""
            formInput.siteID = siteID ?? .zero
            formInput.offlineLicenseToken = credentials.supplementaryCredentials.offlineLicenseToken ?? ""

        case .sharedKey(let appID, let sharedKey, let siteID):
            formInput.appID = appID
            formInput.sharedKey = sharedKey
            formInput.siteID = siteID ?? .zero
            formInput.offlineLicenseToken = credentials.supplementaryCredentials.offlineLicenseToken ?? ""

        case .manual(let certificateConfig):
            formInput.certificateConfig = certificateConfig

        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }

    /// Converts the current form data into an `Credentials` object.
    ///
    /// This utility method generates an `Credentials` instance based on the values
    /// entered in the form. It creates the appropriate `DittoIdentity` based on the selected identity type,
    /// and adds any necessary supplementary credentials such as authentication tokens or offline license tokens.
    /// - Returns: A fully configured `Credentials` object.
    private func createCredentials() throws -> Credentials {

        // Validate the form values before trying to create a Credentials object
        let validationErrors = formInput.validate()
        if let firstError = validationErrors.first {
            throw DittoServiceError.invalidCredentials(firstError)
        }

        let identity: DittoIdentity

        // Create the appropriate DittoIdentity based on the form data
        switch formInput.identityType {
        case .offlinePlayground:
            identity = .offlinePlayground(
                appID: formInput.appID,
                siteID: formInput.siteID
            )

        case .onlineWithAuthentication:
            identity = .onlineWithAuthentication(
                appID: formInput.appID,
                authenticationDelegate: credentialsService.authenticationDelegate,
                enableDittoCloudSync: formInput.enableDittoCloudSync,
                customAuthURL: URL(string: formInput.customAuthURLString) ?? nil
            )

        case .onlinePlayground:
            identity = .onlinePlayground(
                appID: formInput.appID,
                token: formInput.playgroundToken,
                enableDittoCloudSync: formInput.enableDittoCloudSync,
                customAuthURL: URL(string: formInput.customAuthURLString)
            )

        case .sharedKey:
            identity = .sharedKey(
                appID: formInput.appID,
                sharedKey: formInput.sharedKey,
                siteID: formInput.siteID
            )

        case .manual:
            identity = .manual(certificateConfig: formInput.certificateConfig)

        @unknown default:
            throw DittoServiceError.invalidCredentials("Unsupported or unknown Ditto Identity type encountered.")
        }

        // Create supplementary credentials (optional)
        let supplementaryCredentials = SupplementaryCredentials(
            authProvider: formInput.authProvider,
            authToken: formInput.authToken,
            offlineLicenseToken: formInput.offlineLicenseToken
        )

        // Create Credentials
        let credentials = Credentials(identity: identity, supplementaryCredentials: supplementaryCredentials)

        // Return the fully validated Credentials object
        return credentials
    }

    func canClearCredentials() -> Bool {
        credentialsService.activeCredentials != nil
    }

    /// Handles the "Apply" action by validating and persisting the form data
    func apply() throws {
        do {
            // Convert to Credentials
            let credentials = try createCredentials()

            // Initialize Ditto
            try dittoService.initializeDitto(with: credentials)

            // Clear validation errors on success
            validationErrors = []

        } catch let error as DittoServiceError {
            // Handle DittoServiceError cases
            switch error {
            case .invalidCredentials(let message):
                validationErrors = ["Invalid credentials: \(message)"]
            case .initializationFailed(let reason):
                validationErrors = ["Ditto initialization failed: \(reason)"]
            case .syncFailed(let reason):
                validationErrors = ["Failed to start the sync engine: \(reason)"]
            default:
                break
            }
            throw error
        } catch {
            // Handle unexpected errors
            validationErrors = ["An unexpected error occurred: \(error.localizedDescription)"]
            throw error
        }
    }

    func clearCredentials() {
        dittoService.destroyDittoInstance(clearingCredentials: true)
        self.formInput = IdentityFormInput()
        print("CredentialsView: Credentials cleared.")
    }
}
