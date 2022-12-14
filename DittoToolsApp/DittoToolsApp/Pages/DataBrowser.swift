//
//  DataBrowser.swift
//  debug
//
//  Created by Rae McKelvey on 8/9/22.
//

import SwiftUI
import DittoSwift
import Combine
import DittoDataBrowser

struct DataBrowserView: View {
   
    var body: some View {
       DataBrowser(ditto: DittoManager.shared.ditto!)
//       List {
//          ForEach(DittoManager.shared.colls) { collection in
//             let internalCollection: Bool = collection.name.starts(with: "__")
//             NavigationLink {
//                CollectionView(name: collection.name)
//             } label: {
//                MenuListItem(title: collection.name, systemImage: internalCollection ? "lock": "envelope", color: internalCollection ? .black : .blue)
//             }
//
//          }
//       }.navigationTitle("Collections")
    }
}

struct DataBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        DataBrowserView()
    }
}

extension DittoCollection: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return name.hashValue
    }
}
