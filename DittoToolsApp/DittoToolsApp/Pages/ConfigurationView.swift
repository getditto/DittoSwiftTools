//
//  ConfigurationView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

fileprivate class ViewModel: ObservableObject {
    @ObservedObject var dittoManager = DittoManager.shared
    @Published var isPresentingAlert = false
    var error: String = ""

    @Published var mutableConfig = MutableConfig()

    init () {
        self.mutableConfig = dittoManager.config
    }

    var isDisabled: Bool {
        return DittoManager.shared.config.appID.count < 3
    }

    func changeIdentity() {
        dittoManager.config = mutableConfig
        do {
            try dittoManager.restartDitto()
        } catch let err {
            print("Error when starting ditto \(err)")
            self.isPresentingAlert = true
            self.error = err.localizedDescription
        }
    }
}


struct ConfigurationView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject fileprivate var viewModel = ViewModel()

    var body: some View {
        NavigationView {
            HStack {
#if os(tvOS)
                Image(systemName: "gear")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity) // Takes 50% of the width
                    .fontWeight(.medium)
                    .padding(200)
                    .blendMode(.overlay)
#endif
                Form {
                    Section {
                        Picker("Identity", selection: $viewModel.mutableConfig.identityType) {
                            Label("Online Playground", systemImage: "globe").tag(IdentityType.onlinePlayground)
                            Label("Offline Playground", systemImage: "antenna.radiowaves.left.and.right.slash").tag(IdentityType.offlinePlayground)
                            Label("Online with Authentication", systemImage: "lock.shield").tag(IdentityType.onlineWithAuthentication)
                        }
                    }
                    
                    Section {
                        
                        // App ID
                        ConfigurationTextField(label: "App ID", placeholder: "YOUR_APP_ID", text: $viewModel.mutableConfig.appID)
                        
                        
                        switch (viewModel.mutableConfig.identityType) {
                        case IdentityType.onlinePlayground:
                            
                            // Playground Token
                            ConfigurationTextField(label: "Playground Token", placeholder: "YOUR_PLAYGROUND_TOKEN", text: $viewModel.mutableConfig.playgroundToken)
                            
                        case IdentityType.offlinePlayground:
                            
                            // Offline License Token
                            ConfigurationTextField(label: "Offline License Token", placeholder: "YOUR_OFFLINE_LICENSE", text: $viewModel.mutableConfig.offlineLicenseToken)
                            
                        case IdentityType.onlineWithAuthentication:
                            
                            // Authentication Provider
                            ConfigurationTextField(label: "Authentication Provider", placeholder: "Provider name", text: $viewModel.mutableConfig.authenticationProvider)
                            
                            // Authentication Token
                            ConfigurationTextField(label: "Authentication Token", placeholder: "AUTHENTICATION_TOKEN", text: $viewModel.mutableConfig.authenticationToken)
                        }
                    }
                }
            }
            .navigationTitle("Configuration")
#if os(tvOS)
            .navigationBarItems(
                trailing: Button("Apply") {
                    applyChanges()
                })
            
#else
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Apply") {
                        applyChanges() // Apply changes and dismiss the sheet
                    }
                }
                ToolbarItemGroup(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
#endif
        }
        .interactiveDismissDisabled()
    }
    
    func applyChanges() {
        viewModel.changeIdentity()
        dismiss()
    }
}


struct ConfigurationTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.system(.subheadline))
                .fontWeight(.bold)
            
            HStack {
                TextField(placeholder, text: $text)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onAppear {
                        UITextField.appearance().clearButtonMode = .whileEditing
                    }
                    .submitLabel(.done)
                
#if canImport(UIKit) && !os(tvOS)
                Button(action: {
                    if let clipboardText = UIPasteboard.general.string {
                        text = clipboardText // Set the value of the TextField to the clipboard content
                    }
                }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .labelStyle(.iconOnly)
                }
#endif
            }
        }
    }
}


struct DemoLoginPage_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationView()
            .preferredColorScheme(.dark)
    }
}
