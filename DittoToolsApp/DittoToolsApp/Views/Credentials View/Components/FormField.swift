//
//  FormField.swift
//
//  Copyright © 2025 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

// MARK: - FormFieldType

/// Defines the type of input for a form field.
enum FormFieldType: Equatable {
    case text(TextSubtype)
    case number
    case boolean

    /// Subtypes for text input fields.
    enum TextSubtype {
        case plain
        case url
        case uuid
        case base64
    }

    #if !os(macOS)
    /// The appropriate keyboard type for the field.
    var keyboardType: UIKeyboardType {
        switch self {
        case .text(let subtype):
            switch subtype {
            case .url:
                return .URL
            default:
                return .default
            }
        case .number:
            return .numberPad
        case .boolean:
            return .default
        }
    }
    #endif
}

// MARK: - FormField View

/// A SwiftUI component for rendering input fields.
///
/// Dynamically adjusts its appearance and behavior based on the field type and bindings.
///
/// - Supports text, numeric, and toggle fields.
/// - Example:
/// ```swift
/// FormField(type: .text(.uuid), label: "App ID", value: $appID)
/// FormField(label: "Enable Feature", value: $isFeatureEnabled)
/// ```
struct FormField: View {
    let type: FormFieldType
    let label: String

    @Binding var stringValue: String
    @Binding var intValue: UInt64
    @Binding var boolValue: Bool

    var placeholder: String?

    var isRequired: Bool = false

    @State private var isTextFieldFocused: Bool = false

    var body: some View {
        Group {
            #if os(tvOS)
                HStack {
                    content
                }
            #else
                VStack(alignment: .leading) {
                    content
                }
                .padding(.vertical, 3)
            #endif
        }
    }

    /// Renders the field's content based on its type.
    @ViewBuilder
    private var content: some View {
        // Label and Optional Indicator
        if type != .boolean {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
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
            .layoutPriority(1)
        }

        // Render Field Based on Type
        switch type {
        case .text(let subtype):
            clearableTextField(subtype: subtype)
        case .number:
            numberField
        case .boolean:
            booleanField
        }
    }

    /// A custom `TextField` with a clear button that mimics the iOS 15+ behavior but works on iOS 14.
    ///
    /// `ClearableTextField` is a reusable component that allows users to clear the text in a `TextField` by tapping an "x" button,
    /// similar to the built-in `UITextField` behavior introduced in iOS 15. The clear button appears when the field is focused, and text is entered.
    /// It is designed to work on platforms other than tvOS.
    @ViewBuilder
    private func clearableTextField(subtype: FormFieldType.TextSubtype) -> some View {
        HStack {
            #if os(macOS)
            TextField(
                text: $stringValue,
                prompt: Text(placeholder ?? placeholderText(for: type) ?? "")
            ) {
                Text("")
            }
            .autocorrectionDisabled()
            .multilineTextAlignment(textAlignment)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            #else
            TextField(
                placeholder ?? placeholderText(for: type) ?? "",
                text: $stringValue,
                onEditingChanged: { isEditing in
                    isTextFieldFocused = isEditing
                }
            )
            .keyboardType(type.keyboardType)
            .autocapitalization(subtype == .uuid ? .allCharacters : .none)
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            .multilineTextAlignment(textAlignment)
            #endif
            
            #if !os(tvOS)
            Image(systemName: "xmark.circle.fill")
            #if !os(macOS)
                .foregroundColor(Color(UIColor.tertiaryLabel))  // Semantic colors for light/dark mode
            #endif
                .opacity(!stringValue.isEmpty && isTextFieldFocused ? 1 : 0)  // Fade animation
                .animation(.easeInOut(duration: 0.1), value: stringValue)
                .animation(.easeInOut(duration: 0.1), value: isTextFieldFocused)
                .onTapGesture { stringValue = "" }
            #endif
        }
    }

    /// Renders a text field for numeric input.
    @ViewBuilder
    private var numberField: some View {
        TextField(placeholder ?? "", value: $intValue, formatter: NumberFormatter())
        #if !os(macOS)
            .keyboardType(type.keyboardType)
            .font(.system(.body, design: .monospaced))
        #endif
            .autocorrectionDisabled()
            .multilineTextAlignment(textAlignment)
    }

    /// Renders a toggle switch for boolean input.
    @ViewBuilder
    private var booleanField: some View {
        Toggle(label, isOn: $boolValue)
    }

    /// Provides a default placeholder for the field type, if applicable.
    private func placeholderText(for type: FormFieldType) -> String? {
        switch type {
        case .text(let subtype):
            switch subtype {
            case .url:
                return "https://example.com"
            case .uuid:
                return "123e4567-e89b-12d3-a456-426614174000"
            case .base64:
                return "Base64-encoded Certificate"
            default:
                return nil
            }
        default:
            return nil
        }
    }

    /// Determines text alignment based on platform.
    private var textAlignment: TextAlignment {
        #if os(tvOS)
            .trailing
        #else
            .leading
        #endif
    }
}

// MARK: - Initializers

extension FormField {

    /// Initializer for text fields.
    init(type: FormFieldType, label: String, value: Binding<String>, placeholder: String? = nil, isRequired: Bool = false) {
        self.type = type
        self.label = label
        self.placeholder = placeholder
        self._stringValue = value
        self._intValue = .constant(0)
        self._boolValue = .constant(false)
        self.isRequired = isRequired
    }

    /// Initializer for numeric fields.
    init(label: String, value: Binding<UInt64>, placeholder: String? = nil, isRequired: Bool = false) {
        self.type = .number
        self.label = label
        self.placeholder = placeholder
        self._stringValue = .constant("")
        self._intValue = value
        self._boolValue = .constant(false)
        self.isRequired = isRequired
    }

    /// Initializer for boolean-based fields
    init(label: String, value: Binding<Bool>) {
        self.type = .boolean
        self.label = label
        self._stringValue = .constant("")
        self._intValue = .constant(0)
        self._boolValue = value
        self.isRequired = true
    }
}
