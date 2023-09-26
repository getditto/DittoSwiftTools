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
    @State var startSubscriptions: Bool = false
    @State var isStandAlone: Bool = false
    
    public init(ditto: Ditto) {
        self._viewModel = StateObject(wrappedValue: DataBrowserViewModel(ditto: ditto))
    }
    
    public var body: some View {
        if #available(iOS 15.0, *) {
            GeometryReader { geo in
                VStack {
                    Button {
                        self.startSubscriptions = true
                    } label: {
                        Text("Start Subscriptions")
                    }
                    .frame(width: geo.size.width, alignment: .leading).padding([.leading], 25)
                    .alert("Stand Alone App?", isPresented: $startSubscriptions) {
                        Button("Cancel", role: .cancel) { }
                        Button("Start", role: .none) {
                            viewModel.startSubscription()
                            self.isStandAlone = true
                        }
                    } message: {
                        Text("Only start subscriptions if using the Data Browser in a stand alone application")
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
            }
            .navigationTitle("Collections")
            .onDisappear(perform: {
                viewModel.closeLiveQuery()
            })
        } else {
            // Fallback on earlier versions
        }
    }

}
