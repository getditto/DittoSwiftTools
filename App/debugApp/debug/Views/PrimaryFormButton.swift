
import SwiftUI

struct PrimaryFormButton: View {

    var action: (() -> Void)?
    var text: String
    var textColor: Color = .accentColor
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                if !isDisabled {
                    action?()
                }
            }, label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                    }
                    Text(text)
                        .foregroundColor(textColor)
                        .fontWeight(.bold)
                }
            })
            Spacer()
        }
    }
}

struct PrimaryFormButton_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section {
                PrimaryFormButton(text: "Save")
            }
        }
    }
}
