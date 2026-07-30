//
//  DataBrowserApp.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

public struct DataBrowser: View {
    
    @StateObject var viewModel: DataBrowserViewModel
    
    public init(ditto: Ditto) {
        self._viewModel = StateObject(wrappedValue: DataBrowserViewModel(ditto: ditto))
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            #if os(macOS)
            NavigationView {
                listView
            }
            #else
            listView
            #endif
        }
        .navigationTitle("Collections")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var listView: some View {
        List {
            Section {
                ForEach(viewModel.collectionNames, id: \.self) { name in
                    NavigationLink(destination: Documents(collectionName: name, ditto: viewModel.ditto)) {
                        Text(name)
                    }
                }
            }
        }
        #if os(iOS)
        .padding(.top, -16)
        #endif
    }
}
