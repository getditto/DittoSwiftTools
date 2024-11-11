// 
//  IdentityFormTextField.swift
//
//  This file defines a customizable form text field component that includes support for optional or required labels.
//  The component adapts its layout and behavior depending on the platform (i.e., different behavior for tvOS and non-tvOS platforms).
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

/// A form text field component that displays a label and optional or required indicators,
/// and provides platform-specific behavior.
///
/// `IdentityFormTextField` offers a customizable form field for user input. It includes a clearable text field on non-tvOS platforms
/// and a "Paste" button to allow the user to paste content from the clipboard.
/// On tvOS, the component behaves differently, removing the clearable field and clipboard interaction.
struct IdentityFormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    
    var body: some View {
        
#if os(tvOS)
        // On tvOS, we display a basic VStack without the clearable text field or clipboard functionality.
        VStack(alignment: .leading) {
            Text(label + "\(isRequired ? " (required)" : "")")
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
                }
                ClearableTextField(placeholder: placeholder, text: $text)
            }
 
            Spacer()
            
            Button(action: {
                if let clipboardText = UIPasteboard.general.string {
                    text = clipboardText // Set the value of the TextField to the clipboard content
                }
            }) {
                Label("Paste", systemImage: "doc.on.clipboard.fill")
                    // .font(.subheadline)
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless) // ensure only the button handles a tap
        }
#endif
    }
}
