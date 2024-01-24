//
//  DataBrowser.swift
//  debug
//
//  Created by Rae McKelvey on 8/9/22.
//

import Combine
import DittoDataBrowser
import DittoSwift
import SwiftUI

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

