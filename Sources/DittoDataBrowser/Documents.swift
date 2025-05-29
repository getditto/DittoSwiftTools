//
//  Documents.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import SwiftUI
import DittoSwift
import Utils

struct Documents: View {
    
    @StateObject var viewModel: DocumentsViewModel
    @State var querySearch = ""
    @State private var isShowingDocPicker = false
    @State private var isEditing: Bool = false

        
    init(collectionName: String, ditto: Ditto, isStandAlone: Bool) {
        self._viewModel = StateObject(wrappedValue: DocumentsViewModel(collectionName: collectionName, ditto: ditto, isStandAlone: isStandAlone))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                queryBar
                documentDropDown
                detailsView
            }
            .padding()
            #if os(iOS)
            .navigationTitle(viewModel.collectionName)
            #else
            .navigationTitle("Collections: " + viewModel.collectionName)
            #endif
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading) {
            if viewModel.docsList.indices.contains(viewModel.selectedDoc) {
                ForEach(viewModel.docProperties ?? [], id: \.self) { property in
                    HStack {
                        if let temp = viewModel.docsList[viewModel.selectedDoc].value[property], let val = temp {
                            Text(property + ":")
                            Text(String(describing: val))
                        }
                    }
                    #if os(tvOS)
                    .focusable(true)
                    #endif
                }
            } else {
                Text("No document selected or query returned no results.")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        #if os(iOS)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        #elseif os(tvOS)
        .padding()
        #endif
    }

    
    private var queryBar: some View {
        VStack(alignment: .leading) {
            Text("Query Documents")
                .font(.headline)
            HStack {
                #if os(tvOS)
                Button(action: {
                    isEditing = true
                }) {
                    HStack {
                        Text("Query Documents")
                        Spacer()
                        Text(querySearch)
                        Image(systemName: "chevron.right")
                    }
                }
                .background(KeyboardOverlay(text: $querySearch, isPresented: $isEditing, keyboardType: .default))
                #else
                TextField("name == \"Ham's Burgers\"", text: $querySearch, onCommit: {viewModel.filterDocs(queryString: querySearch)})
                    .textFieldStyle(.roundedBorder)
                #endif
                #if os(macOS) || os(tvOS)
                Button {
                    viewModel.filterDocs(queryString: querySearch)
                } label: {
                    Text("Enter")
                }
                #endif
            }
            Text("This is a filter mechanism for DQL queries. It's as if you already have the 'SELECT * FROM " + viewModel.collectionName + " WHERE' applied, so you add the filtering criteria. Ex: name == \"Ham's Burgers\"")
                .font(.caption)
            Link("Learn how to write DQL queries",
                 destination: URL(string: "https://docs.ditto.live/dql/dql")!)
                .font(.caption)
        }
        .padding(.bottom)
        .onDisappear(perform: {
            viewModel.closeLiveQuery()
        })
    }
    
    private var documentDropDown: some View {
        HStack {
            #if os(iOS) || os(tvOS)
            NavigationLink(
                destination: DocumentSelectionView(
                    selectedIndex: $viewModel.selectedDoc,
                    documents: viewModel.docsList
                ),
                isActive: $isShowingDocPicker
            ) {
                Button(action: {
                    isShowingDocPicker = true
                }) {
                    HStack {
                        Text(viewModel.docsList.indices.contains(viewModel.selectedDoc) ?
                             viewModel.docsList[viewModel.selectedDoc].id :
                             "Select Document")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    #if os(iOS)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    #endif
                }
                .buttonStyle(PlainButtonStyle())
            }
            #else
            Picker("Select a Document:", selection: $viewModel.selectedDoc) {
                ForEach(0 ..< viewModel.docsList.count, id: \.self) {
                    Text(viewModel.docsList[$0].id)
                }
            }
            #endif
        }
    }

}

struct DocumentSelectionView: View {
    @Binding var selectedIndex: Int
    let documents: [Document]
    
    var body: some View {
        VStack {
            List(0..<documents.count, id: \.self) { index in
                Button(action: {
                    selectedIndex = index
                }) {
                    HStack {
                        Text(documents[index].id)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(index == selectedIndex ? Color.blue : Color.clear)
                            .font(.headline)
                    }
                }
            }
            #if os(iOS)
            .navigationTitle("Select Document")
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .listStyle(.plain)
        }
    }
}
