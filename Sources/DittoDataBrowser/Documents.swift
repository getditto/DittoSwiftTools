//
//  Documents.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

#if !os(macOS)

import SwiftUI
import DittoSwift

#if canImport(UIKit)
import UIKit
#endif

struct Documents: View {
    
    @StateObject var viewModel: DocumentsViewModel
    @State var querySearch = ""
        
    init(collectionName: String, ditto: Ditto, isStandAlone: Bool) {
        self._viewModel = StateObject(wrappedValue: DocumentsViewModel(collectionName: collectionName, ditto: ditto, isStandAlone: isStandAlone))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Collection: " + viewModel.collectionName)
                .font(.title2)
                .frame(alignment: .topLeading)
                .padding(.leading)
            SearchBar(searchText: $querySearch, viewModel: viewModel)

            HStack {
                if(!viewModel.docsList.isEmpty) {
                    Text("Docs: " + String(viewModel.docsList.count))
                    .frame(alignment: .topLeading)
                    .padding(.leading)
                }
                else {
                    Text("Docs: 0")
                    .frame(alignment: .topLeading)
                    .padding(.leading)
                }
                Spacer()

                if(!viewModel.docsList.isEmpty) {
                    if #available(tvOS 17.0, *) {
                        Menu {
                            Picker(selection: $viewModel.selectedDoc, label: Text("Select a Document")) {
                                ForEach(0 ..< viewModel.docsList.count, id: \.self) {
                                    Text(viewModel.docsList[$0].id)
                                        .bold()
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "doc")
                                Text("Select Document")
                            }
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal)
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    HStack {
                        Image(systemName: "doc")
                        Text("No Documents Found")
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                }
            }
            .frame(alignment: .topLeading)

            Rectangle()
                .fill(.gray)
                .frame(height: 4)
                .padding(.bottom)

            if(viewModel.docsList.isEmpty) {
                HStack {
                    Spacer()
                    Text("No Data")
                    Spacer()
                }
            }
            else {
                Text("Docs Count: 0")
                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
                .padding(.leading)
            }
            HStack {
         
                Text("Doc ID:")
                    .padding(.leading)
           
                if(!viewModel.docsList.isEmpty) {
                    if #available(tvOS 17.0, *) {
                        Picker(selection: $viewModel.selectedDoc, label: Text("Select a Document")) {
                            ForEach(0 ..< viewModel.docsList.count, id: \.self) {
                                Text(viewModel.docsList[$0].id)
                                    .bold()
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker(selection: $viewModel.selectedDoc, label: Text("Select a Document")) {
                            ForEach(0 ..< viewModel.docsList.count, id: \.self) {
                                Text(viewModel.docsList[$0].id)
                                    .bold()
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                }
            }
            .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)

                Divider()
                    .frame(height: 4)
                    .padding(.bottom)

            
            HStack {
                VStack {
                    
                    if(viewModel.docsList.isEmpty) {
                        Text("No Data")
                    }
                    else {
                        ScrollView {
                            ForEach(viewModel.docProperties ?? [], id: \.self) {property in
                                HStack {
                                    Text(property + ":")
                                        .padding(.leading)
                                    
                                    if let temp = viewModel.docsList[viewModel.selectedDoc].value[property], let val = temp {
                                        Text(String.init(describing: val))
                                    }
                                    
                                }
                            }
#if os(tvOS)
                            .focusable(true)
#endif

                            Divider()
                        }
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @ObservedObject var viewModel: DocumentsViewModel
        
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Query", text: $searchText)
#if !os(tvOS)
                    .textFieldStyle(.roundedBorder)
#else
                    .textFieldStyle(.automatic)
#endif
            }
            .padding(5)

            Button {
                viewModel.filterDocs(queryString: searchText)
            } label: {
                Text("Find")
                    .foregroundColor(.white)
            }
            .padding(.vertical, 5)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 13).fill(.blue))

        }
        .padding(.horizontal)
        .onDisappear(perform: {
            viewModel.closeLiveQuery()
        })
    }
}

#endif
