//
//  DataBrowser.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI

struct Collections: View {
    
    @StateObject var viewModel = DataBrowserViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section() {
                    ForEach(viewModel.collections ?? [], id: \.name) { collection in
                        NavigationLink(destination: Documents(collectionName: collection.name)) {
                            Text(collection.name)
                        }
                    }
                }
            }
            .navigationTitle("Collections")
        }
    }
}

struct Collections_Previews: PreviewProvider {
    static var previews: some View {
        Collections()
    }
}
