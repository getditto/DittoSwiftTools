// 
//  IdentityFormInputView.swift
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.
//

import SwiftUI

#warning("TODO: do we need this? I think we can remove it from the implementation, then delete it")

struct IdentityFormIntInputView: View {
    let label: String
    var placeholder: String = ""
    @Binding var int: UInt64
    var isRequired: Bool = false
    
    var body: some View {
        TextField(placeholder, value: $int, formatter: NumberFormatter())
    }
}

enum StringValidation {
    case uuid
    case url
    case base64
}

private extension String {
    func isValidUUID() -> Bool {
        return UUID(uuidString: self) != nil
    }

    func isValidURL() -> Bool {
        return URL(string: self) != nil
    }

    func isValidBase64() -> Bool {
        guard let _ = Data(base64Encoded: self) else {
            return false
        }
        return true
    }
}
