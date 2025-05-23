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

        
    init(collectionName: String, ditto: Ditto, isStandAlone: Bool) {
        self._viewModel = StateObject(wrappedValue: DocumentsViewModel(collectionName: collectionName, ditto: ditto, isStandAlone: isStandAlone))
    }
    
    var body: some View {
        VStack {
            searchBar
            documentDropDown
            Spacer()
        }
        .padding()
        #if os(iOS)
        .navigationTitle(viewModel.collectionName)
        #else
        .navigationTitle("Collections: " + viewModel.collectionName)
        #endif
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Query Documents", text: $querySearch, onCommit: {viewModel.filterDocs(queryString: querySearch)})
                #if !os(tvOS)
                .textFieldStyle(.roundedBorder)
                #endif
            #if os(macOS)
            Button {
                viewModel.filterDocs(queryString: querySearch)
            } label: {
                Text("Enter")
            }
            #endif
        }
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
                EmptyView()
            }
            .frame(width: 0, height: 0)

            Button(action: {
                isShowingDocPicker = true
            }) {
                HStack {
                    Text(viewModel.docsList.indices.contains(viewModel.selectedDoc) ?
                         viewModel.docsList[viewModel.selectedDoc].id :
                         "Select Document")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
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

/*
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
             #if !os(macOS)
             .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
             #endif
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
     #if !os(macOS)
     .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
     #endif

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
 */
