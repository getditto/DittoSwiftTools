
import SwiftUI

struct Login: View {
    @Environment(\.dismiss) var dismiss

    class ViewModel: ObservableObject {
        @ObservedObject var dittoModel = DittoManager.shared
        @Published var isPresentingAlert = false
        var error: String = ""
        @Published var useIsolatedDirectories = true
        @Published var config = DittoConfig()
        
        init () {
            self.config = dittoModel.config
        }

        var isDisabled: Bool {
            return DittoManager.shared.config.appID.count < 3
        }
        
        func changeIdentity() {
            dittoModel.config = config
            do {
                try dittoModel.restartDitto()
            } catch let err {
                print("Error when starting ditto \(err)")
                self.isPresentingAlert = true
                self.error = err.localizedDescription
            }
        }
    }
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Picker("Identity", selection: $viewModel.config.identityType) {
                            Text("Online Playground").tag(IdentityType.onlinePlayground)
                            Text("Offline Playground").tag(IdentityType.offlinePlayground)
                            Text("Online With Authentication").tag(IdentityType.onlineWithAuthentication)
                        }
                    }
                    HStack {
                        Text("App ID")
                        TextField("", text: $viewModel.config.appID)
                    }
                    switch (viewModel.config.identityType) {
                    case IdentityType.onlinePlayground:
                        HStack {
                            Text("Playground Token")
                            TextField("", text: $viewModel.config.playgroundToken)
                        }
                    case IdentityType.offlinePlayground:
                        HStack {
                            Text("Offline License Token")
                            TextField("", text: $viewModel.config.offlineLicenseToken).textInputAutocapitalization(.never)
                        }
                    case IdentityType.onlineWithAuthentication:
                        HStack {
                            Text("Provider")
                            TextField("", text: $viewModel.config.authenticationProvider).textInputAutocapitalization(.never)
                        }
                        HStack {
                            Text("Token")
                            TextField("", text: $viewModel.config.authenticationToken).textInputAutocapitalization(.never)
                        }
                    }
                }
                Section {
                    PrimaryFormButton(action: {
                        viewModel.changeIdentity()
                        dismiss()
                    }, text: "Restart Ditto", textColor: viewModel.isDisabled ? .secondary : .accentColor, isLoading: false, isDisabled: false)
                }
            }
            .navigationTitle("")
            /*
            .sheet(isPresented: $viewModel.isPresentingImagePicker, content: {
                ImagePicker(sourceType: viewModel.sourceType, isSquareMode: true) { image in
                    let file = try! File.insert(image: image)
                    viewModel.fileId = file._id
                    viewModel.image = image
                }
            }) */
            .alert("Ditto failed to start.", isPresented: $viewModel.isPresentingAlert, actions: {
                    Button("Dismiss", role: .cancel) { dismiss() }
                })
            }
    }
}

struct DemoLoginPage_Previews: PreviewProvider {
    static var previews: some View {
        Login()
            .preferredColorScheme(.dark)
    }
}
