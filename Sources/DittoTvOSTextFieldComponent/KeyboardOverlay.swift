//
//  TVKeyboardOverlay.swift
//  DittoSwiftTools
//
//  Created by Alec Coyner on 5/23/25.
//

#if os(tvOS)
import SwiftUI
import UIKit

public struct KeyboardOverlay: UIViewControllerRepresentable {
    @Binding var text: String
    @Binding var isPresented: Bool
    var keyboardType: UIKeyboardType

    public init(text: Binding<String>, isPresented: Binding<Bool>, keyboardType: UIKeyboardType = .default) {
        self._text = text
        self._isPresented = isPresented
        self.keyboardType = keyboardType
    }

    public class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KeyboardOverlay
        weak var textField: UITextField?

        init(_ parent: KeyboardOverlay) {
            self.parent = parent
        }

        public func textFieldDidEndEditing(_ textField: UITextField) {
            parent.text = textField.text ?? ""
            parent.isPresented = false
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear

        // Create the text field once and store it on the coordinator for reuse.
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.isHidden = true
        vc.view.addSubview(textField)
        context.coordinator.textField = textField

        return vc
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let textField = context.coordinator.textField else { return }
        textField.keyboardType = keyboardType
        if isPresented {
            textField.text = text
            textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }
}
#endif
