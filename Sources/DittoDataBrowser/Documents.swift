//
//  Documents.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import SwiftUI
import DittoSwift

#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, *)
struct Documents: View {
    
    @StateObject var viewModel: DocumentsViewModel
    @State var querySearch = ""
        
    init(collectionName: String, ditto: Ditto, isStandAlone: Bool) {
        self._viewModel = StateObject(wrappedValue: DocumentsViewModel(collectionName: collectionName, ditto: ditto, isStandAlone: isStandAlone))
    }
    
    var body: some View {
        VStack {
            Text("Collection: " + viewModel.collectionName)
                .font(.title2)
                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
                .padding(.leading)
            SearchBar(searchText: $querySearch, viewModel: viewModel)
            if(!viewModel.docsList.isEmpty) {
                Text("Docs Count: " + String(viewModel.docsList.count))
                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
                .padding(.leading)
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
                    Picker(selection: $viewModel.selectedDoc, label: Text("Select a Document")) {
                        ForEach(0 ..< viewModel.docsList.count, id: \.self) {
                            Text(viewModel.docsList[$0].id)
                                .bold()
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    }
                    .pickerStyle(.menu)
                    
                }
            }
            .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)

                Divider()
                    .frame(height: 4)
                    .overlay(.gray)
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
                                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, minHeight: 0, maxHeight: UIScreen.main.bounds.height, alignment: .topLeading)
                                
                                Divider()
                                    .frame(width: UIScreen.main.bounds.width)
                                
                            }
                        }
                    }
                }

            }
            
        }
        .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width, minHeight: 0, maxHeight: UIScreen.main.bounds.height, alignment: .topLeading)
    }
}

//struct Documents_Previews: PreviewProvider {
//    static var previews: some View {
//        Documents(collectionName: "Default")
//    }
//}

@available(iOS 15.0, *)
struct SearchBar: View {
    
    @Binding var searchText: String
    @ObservedObject var viewModel: DocumentsViewModel
        
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color(UIColor.systemGray5))
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Query", text: $searchText)
                }
                .foregroundColor(Color(UIColor.darkGray))
                .padding(.leading, 13)
                
            }
            .frame(height: 30)
            .cornerRadius(13)
            .padding([.top,.leading,.bottom])
        
            Button {
                viewModel.filterDocs(queryString: searchText)
            } label: {
                Text("Find")
                    .frame(height: 30)
                    .padding([.leading, .trailing])
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 13).fill(.blue))
            }
            .padding(.trailing)

        }
        .onDisappear(perform: {
            viewModel.closeLiveQuery()
        })
    }
}
