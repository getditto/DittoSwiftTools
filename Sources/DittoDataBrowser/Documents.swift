//
//  Documents.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import SwiftUI
import DittoSwift

struct Documents: View {
    
    @StateObject var viewModel: DocumentsViewModel
    @State var querySearch = ""
    @State private var isShowingDocPicker = false

    init(collectionName: String, ditto: Ditto) {
        self._viewModel = StateObject(
            wrappedValue: DocumentsViewModel(collectionName: collectionName, ditto: ditto)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                queryBar
                errorMessages
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
        #endif
    }

    private var errorMessages: some View {
        VStack(spacing: 12) {
            if let error = viewModel.documentsErrorMessage {
                errorMessage(error)
            }
        }
        .padding(.bottom)
    }

    private func errorMessage(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.red.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    
    private var queryBar: some View {
        VStack(alignment: .leading) {
            #if os(iOS) || os(macOS)
            Text("Query Documents")
                .font(.headline)
            #endif
            HStack {
                TextField(
                    "color = 'blue'",
                    text: $querySearch,
                    onCommit: runQuery
                )
                    .textFieldStyle(.roundedBorder)
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                #endif
                Button("Run", action: runQuery)
            }
            Text("Enter a DQL `WHERE` expression, for example: color = 'blue'")
                .font(.caption)
            Text(viewModel.queryStatus)
                .font(.caption)
                .foregroundColor(.accentColor)
            #if os(iOS) || os(macOS)
            Link("Learn how to use DQL",
                 destination: URL(string: "https://docs.ditto.live/dql/dql")!)
                .font(.caption)
            #endif
        }
        .padding(.bottom)
        .onDisappear(perform: {
            viewModel.closeLiveQuery()
        })
    }

    private func runQuery() {
        viewModel.filterDocs(queryString: querySearch)
    }
    
    private var documentDropDown: some View {
        HStack {
            #if os(iOS)
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
