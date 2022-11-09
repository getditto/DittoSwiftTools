//
//  DataBrowser.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI

struct DataBrowser: View {
    
    @StateObject var viewModel = DataBrowserViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Collections")) {
                    ForEach(viewModel.collections ?? [], id: \.name) { collection in
                        NavigationLink(destination: Documents(collectionName: collection.name)) {
                            Text(collection.name)
                        }
                    }
                }
            }
            .navigationTitle("Data Browser")
        }
    }
}

struct DataBrowser_Previews: PreviewProvider {
    static var previews: some View {
        DataBrowser()
    }
}
