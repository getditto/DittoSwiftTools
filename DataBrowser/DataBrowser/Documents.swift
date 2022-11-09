//
//  Documents.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/7/22.
//

import SwiftUI

struct Documents: View {
    
    @StateObject var viewModel: DocumentsViewModel
    
    init(collectionName: String) {
        self._viewModel = StateObject(wrappedValue: DocumentsViewModel(collectionName: collectionName))
    }
    
    var body: some View {

        Text(viewModel.collectionName)
        VStack {
            ForEach(viewModel.docProperties ?? [], id: \.description) {property in
                HStack {
                    Text(property.description)
                    VStack {
                        ForEach(viewModel.docsList, id: \.self) { doc in
                            
                            if(doc.value[property] != nil) {
                                Text(doc.value[property]!.debugDescription.replacingOccurrences(of: "Optional(", with: ""))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct Documents_Previews: PreviewProvider {
    static var previews: some View {
        Documents(collectionName: "Default")
    }
}
