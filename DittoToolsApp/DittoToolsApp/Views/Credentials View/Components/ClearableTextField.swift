//
//  ClearableTextField.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

/// A custom `TextField` with a clear button that mimics the iOS 15+ behavior but works on iOS 14.
///
/// `ClearableTextField` is a reusable component that allows users to clear the text in a `TextField` by tapping an "x" button,
/// similar to the built-in `UITextField` behavior introduced in iOS 15.
/// The clear button appears when the field is focused, and text is entered.
/// It is designed to work on platforms other than tvOS.
struct ClearableTextField: View {
    let placeholder: String
    @Binding var text: String
    
    @State private var isTextFieldFocused: Bool = false
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text, onEditingChanged: { isEditing in
                isTextFieldFocused = isEditing
            })
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            .autocapitalization(.none)
            
#if !os(tvOS)
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color(UIColor.tertiaryLabel)) // Semantic colors for light/dark mode
                .opacity(!text.isEmpty && isTextFieldFocused ? 1 : 0) // Fade animation
                .animation(.easeInOut(duration: 0.1), value: text)
                .animation(.easeInOut(duration: 0.1), value: isTextFieldFocused)
                .onTapGesture { text = "" }
#endif
        }
    }
}
