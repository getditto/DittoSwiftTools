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
        return vc
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented else { return }

        let textField = UITextField()
        textField.text = text
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType  // 🔑 Keypad, email, number, etc.
        textField.becomeFirstResponder()
        uiViewController.view.addSubview(textField)
        textField.isHidden = true
    }
}
#endif
