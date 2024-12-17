// 
//  IdentityFormTextField.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

/// A customizable form text field component with platform-specific behavior.
///
/// `IdentityFormTextField` is a SwiftUI component designed for user input within forms.
/// It displays a label, supports optional or required fields, and includes a placeholder for the text input.
/// - On non-tvOS platforms, the component includes a clearable text field and a "Paste" button for clipboard interaction.
/// - On tvOS, it simplifies the layout by removing clipboard and clearing features.
struct IdentityFormTextField: View {
    
    /// The label displayed above the text field.
    let label: String
    
    /// The placeholder text shown inside the text field when empty.
    let placeholder: String
    
    /// The text binding for the field's content.
    @Binding var text: String
    
    /// A flag indicating whether the field is required.
    /// - If `true`, no "(Optional)" label will be displayed.
    /// - Defaults to `false`.
    var isRequired: Bool = false
    
    var body: some View {
        
#if os(tvOS)
        // On tvOS, we display a basic VStack without the clearable text field or clipboard functionality.
        VStack(alignment: .leading) {
            // Display the label and optional indicator
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(.subheadline))
                    .fontWeight(.medium)
                
                if !isRequired {
                    Text("(Optional)")
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // Display the text field
            TextField(placeholder, text: $text)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.vertical, 12)
#else
        // On non-tvOS platforms, we display a more advanced layout with an optional clearable text field and paste functionality.
        HStack(spacing: 4) {
            VStack(alignment: .leading) {
                // Display the label and optional indicator
                HStack {
                    Text(label)
                        .font(.system(.subheadline))
                        .fontWeight(.medium)
                    
                    if !isRequired {
                        Text("(Optional)")
                            .textCase(.uppercase)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Paste button to populate the text field with clipboard content
                    Button(action: {
                        if let clipboardText = UIPasteboard.general.string {
                            text = clipboardText // Set the value of the TextField to the clipboard content
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard.fill")
                            .resizable() // Make the image resizable
                            .frame(width: 16, height: 20) // Fix the icon size
                    }
                    .contentShape(Rectangle()) // Extend the tappable area visually
                    .buttonStyle(.borderless) // ensure only the button handles a tap
                }
                
                // Clearable text field for user input
                ClearableTextField(placeholder: placeholder, text: $text)
            }
        }
#endif
    }
}
