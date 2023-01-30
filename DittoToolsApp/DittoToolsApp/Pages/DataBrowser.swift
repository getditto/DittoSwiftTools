//
//  DataBrowser.swift
//  debug
//
//  Created by Rae McKelvey on 8/9/22.
//

import SwiftUI
import DittoSwift
import Combine
import DittoDataBrowser

struct DataBrowserView: View {
   
    var body: some View {
       DataBrowser(ditto: DittoManager.shared.ditto!)
    }
}

struct DataBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        DataBrowserView()
    }
}

