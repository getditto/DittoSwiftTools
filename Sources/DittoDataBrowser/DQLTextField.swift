import SwiftUI

#if os(iOS)
import UIKit

struct DQLTextField: UIViewRepresentable {
    private let placeholder: String
    @Binding private var text: String
    private let onCommit: (String) -> Void

    init(_ placeholder: String, text: Binding<String>, onCommit: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self._text = text
        self.onCommit = onCommit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.placeholder = placeholder
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.returnKeyType = .search
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.delegate = context.coordinator
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        if textField.text != text {
            textField.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DQLTextField

        init(_ parent: DQLTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let text = textField.text ?? ""
            parent.text = text
            parent.onCommit(text)
            return true
        }
    }
}
#elseif os(macOS)
import AppKit

struct DQLTextField: NSViewRepresentable {
    private let placeholder: String
    @Binding private var text: String
    private let onCommit: (String) -> Void

    init(_ placeholder: String, text: Binding<String>, onCommit: @escaping (String) -> Void) {
        self.placeholder = placeholder
        self._text = text
        self.onCommit = onCommit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.commit(_:))
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        context.coordinator.parent = self
        if textField.stringValue != text {
            textField.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: DQLTextField

        init(_ parent: DQLTextField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField,
                  let editor = textField.currentEditor() as? NSTextView else {
                return
            }

            editor.isAutomaticQuoteSubstitutionEnabled = false
            editor.isAutomaticDashSubstitutionEnabled = false
            editor.isAutomaticSpellingCorrectionEnabled = false
            editor.isAutomaticTextReplacementEnabled = false
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            parent.text = textField.stringValue
        }

        @objc func commit(_ textField: NSTextField) {
            parent.text = textField.stringValue
            parent.onCommit(textField.stringValue)
        }
    }
}
#endif
