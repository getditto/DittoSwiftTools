// 
//  IdentityFormViewModel.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//


import SwiftUI
import DittoSwift


class IdentityFormViewModel: ObservableObject {
    // Form fields grouped into a struct
    @Published var formInput: IdentityFormInput

    // Validation errors for the form
    @Published var validationErrors: [String] = []

    private let identityConfigurationService: IdentityConfigurationService
    private let dittoService: DittoService

    // Initializer that automatically adopts active configuration if available
    init(identityConfigurationService: IdentityConfigurationService, dittoService: DittoService) {
        self.identityConfigurationService = identityConfigurationService
        self.dittoService = dittoService
        
        // Initialize formInput with default values
        self.formInput = IdentityFormInput(
            identityType: .onlinePlayground,
            appID: "",
            offlineLicenseToken: "",
            playgroundToken: "",
            enableDittoCloudSync: true,
            authProvider: "",
            authToken: "",
            customAuthURLString: "",
            siteID: .zero,
            sharedKey: "",
            certificateConfig: ""
        )
        
        // Check for an active configuration in the service
        if let configuration = identityConfigurationService.activeConfiguration {
            populateFromConfiguration(configuration)
        }
    }

    /// Populate the ViewModel fields from an IdentityConfiguration
    private func populateFromConfiguration(_ configuration: IdentityConfiguration) {
        formInput.identityType = configuration.identity.identityType
        
        switch configuration.identity {
        case .onlinePlayground(let appID, let token, let enableDittoCloudSync, let customAuthURL):
            formInput.appID = appID
            formInput.playgroundToken = token
            formInput.enableDittoCloudSync = enableDittoCloudSync
            formInput.customAuthURLString = customAuthURL?.absoluteString ?? ""

        case .onlineWithAuthentication(let appID, _, let enableDittoCloudSync, let customAuthURL):
            formInput.appID = appID
            formInput.enableDittoCloudSync = enableDittoCloudSync
            formInput.customAuthURLString = customAuthURL?.absoluteString ?? ""
            formInput.authProvider = configuration.supplementaryCredentials.authProvider ?? ""
            formInput.authToken = configuration.supplementaryCredentials.authToken ?? ""

        case .offlinePlayground(let appID, let siteID):
            formInput.appID = appID ?? ""
            formInput.siteID = siteID ?? .zero
            formInput.offlineLicenseToken = configuration.supplementaryCredentials.offlineLicenseToken ?? ""

        case .sharedKey(let appID, let sharedKey, let siteID):
            formInput.appID = appID
            formInput.sharedKey = sharedKey
            formInput.siteID = siteID ?? .zero
            formInput.offlineLicenseToken = configuration.supplementaryCredentials.offlineLicenseToken ?? ""

        case .manual(let certificateConfig):
            formInput.certificateConfig = certificateConfig
            
        @unknown default:
            fatalError("Encountered an unknown DittoIdentity case.")
        }
    }
    
    /// Converts the current form data into an `IdentityConfiguration` object.
    ///
    /// This utility method generates an `IdentityConfiguration` instance based on the values
    /// entered in the form. It creates the appropriate `DittoIdentity` based on the selected identity type,
    /// and adds any necessary supplementary credentials such as authentication tokens or offline license tokens.
    /// - Returns: A fully configured `IdentityConfiguration` object.
    private func createIdentityConfiguration() throws -> IdentityConfiguration {

        // Validate the form values before trying to create an IdentityConfiguration
        let validationErrors = formInput.validate()
        if let firstError = validationErrors.first {
            throw DittoServiceError.invalidIdentity(firstError)
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
                authenticationDelegate: identityConfigurationService.authenticationDelegate,
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
            throw DittoServiceError.invalidIdentity("Unsupported or unknown identity type encountered.")
        }
        
        // Create supplementary credentials (optional)
        let supplementaryCredentials = SupplementaryCredentials(
            authProvider: formInput.authProvider,
            authToken: formInput.authToken,
            offlineLicenseToken: formInput.offlineLicenseToken
        )
        
        // Create IdentityConfiguration
        let identityConfiguration = IdentityConfiguration(identity: identity, supplementaryCredentials: supplementaryCredentials)

        // Return the fully validated IdentityConfiguration object
        return identityConfiguration
    }
    
    /// Handles the "Apply" action by validating and persisting the form data
    func apply() throws -> Void {
        do {
            // Convert to IdentityConfiguration
            let identityConfiguration = try createIdentityConfiguration()

            // Initialize Ditto
            try dittoService.initializeDitto(with: identityConfiguration)

            // Clear validation errors on success
            validationErrors = []

        } catch let error as DittoServiceError {
            // Handle DittoServiceError cases
            switch error {
            case .invalidIdentity(let message):
                validationErrors = ["Invalid identity configuration: \(message)"]
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
}
