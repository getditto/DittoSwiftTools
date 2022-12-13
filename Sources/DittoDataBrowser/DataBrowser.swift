//
//  DataBrowserApp.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

@available(iOS 14.0, *)
public struct DataBrowser: View {
    
    @StateObject var viewModel: DataBrowserViewModel
    
    public init(ditto: Ditto) {
        self._viewModel = StateObject(wrappedValue: DataBrowserViewModel(ditto: ditto))
    }
    
    public var body: some View {
        if #available(iOS 15.0, *) {
            List {
                Section() {
                    ForEach(viewModel.collections ?? [], id: \.name) { collection in
                        NavigationLink(destination: Documents(collectionName: collection.name, ditto: viewModel.ditto)) {
                            Text(collection.name)
                        }
                    }
                }
            }
            .navigationTitle("Collections")
        } else {
            // Fallback on earlier versions
        }
    }
}
