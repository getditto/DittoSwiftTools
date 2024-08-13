//
//  File.swift
//  
//
//  Created by Walker Erekson on 7/16/24.
//

import Combine
import DittoExportLogs
import DittoSwift
import Foundation

/// A singleton which manages our `Ditto` object.
class DittoManager: ObservableObject {
    
    // MARK: - Properties

    var ditto: Ditto?
    
    @Published var loggingOption: DittoLogger.LoggingOptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton

    /// Singleton instance. All access is via `DittoManager.shared`.
    static var shared = DittoManager()
    
    init() {
        self.loggingOption = DittoLogger.LoggingOptions.error  // initial level value
        
        // subscribe to loggingOption changes
        // make sure log level is set _before_ starting ditto
        $loggingOption
            .sink { [weak self] logOption in
                switch logOption {
                case .disabled:
                    DittoLogger.enabled = false
                default:
                    DittoLogger.enabled = true
                    DittoLogger.minimumLogLevel = DittoLogLevel(rawValue: logOption.rawValue)!
                }
            }
            .store(in: &cancellables)
    }
    
}
      

