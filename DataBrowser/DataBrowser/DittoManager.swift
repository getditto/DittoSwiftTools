//
//  DittoManager.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import Foundation
import DittoSwift

class DittoManager {
    
    static let shared = DittoManager()
    public let ditto: Ditto
    
    init() {
        
        //Data Browser
        ditto = Ditto(identity: .onlinePlayground(appID: "cef0fac8-b44b-40d3-b052-480266ef237c", token: "11411143-8ff2-4345-a17c-e8139ae6145e", enableDittoCloudSync: true))

        do {
            try ditto.startSync()
        } catch (let err){
            print( err.localizedDescription)
        }
        
    }
    
}
