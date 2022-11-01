//
//  DataBrowser.swift
//  debug
//
//  Created by Rae McKelvey on 8/9/22.
//

import SwiftUI
import DittoSwift
import Combine

struct DataBrowser: View {

    var body: some View {
        Text("Collections")
        List {
           ForEach(DittoManager.shared.colls) { collection in
             let internalCollection: Bool = collection.name.starts(with: "__")
             MenuListItem(title: collection.name, systemImage: internalCollection ? "lock": "envelope", color: internalCollection ? .black : .blue)
          }
        }
    }
}

struct DataBrowser_Previews: PreviewProvider {
    static var previews: some View {
        DataBrowser()
    }
}

extension DittoCollection: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return name.hashValue
    }
}
