//
//  DataBrowserApp.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

#if !os(macOS)

import SwiftUI
import DittoSwift

public struct DataBrowser: View {
    
    @StateObject var viewModel: DataBrowserViewModel
    @State var startSubscriptions: Bool = false
    @State var isStandAlone: Bool = false
    
    public init(ditto: Ditto) {
        self._viewModel = StateObject(wrappedValue: DataBrowserViewModel(ditto: ditto))
    }
    
    public var body: some View {
                VStack(alignment: .leading) {
                    if #available(iOS 15.0, *) {
                        Button {
                            self.startSubscriptions = true
                        } label: {
                            Text("Start Subscriptions")
                        }
                        .padding(.leading, 25)
                        .alert("Stand Alone App?", isPresented: $startSubscriptions) {
                            Button("Cancel", role: .cancel) { }
                            Button("Start", role: .none) {
                                viewModel.startSubscription()
                                self.isStandAlone = true
                            }
                        } message: {
                            Text("Only start subscriptions if using the Data Browser in a stand alone application")
                        }
                    } else {
                        Button {
                            self.startSubscriptions = true
                            viewModel.startSubscription()
                            self.isStandAlone = true
                        } label: {
                            Text("Start Subscriptions")
                        }
                        .padding(.leading, 25)
                    }
                    List {
                        Section() {
                            ForEach(viewModel.collections ?? [], id: \.name) { collection in
                                NavigationLink(destination: Documents(collectionName: collection.name, ditto: viewModel.ditto, isStandAlone: self.isStandAlone)) {
                                    Text(collection.name)
                                }
                            }
                        }
                    }
                }
            .navigationTitle("Collections")
            .onDisappear(perform: {
                viewModel.closeLiveQuery()
            })
    }
}

#endif
