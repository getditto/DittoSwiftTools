///
//  DittoLogger+LoggingOptions.swift
//  
//
//  Created by Eric Turner on 6/1/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift

public extension DittoLogger {
    enum LoggingOptions:Int, CustomStringConvertible, CaseIterable, Identifiable {
        case disabled = 0, error, warning, info, debug//, verbose
        
        public var id: Self { self }
        
        public var description: String {
            switch self {
            case .disabled:
                return "disabled"
            case .error:
                return "error"
            case .warning:
                return "warning"
            case .info:
                return "info"
            case .debug:
                return "debug"
// XXX(rae): Hiding verbose from the UI because users are tempted to use it, 
// but performance can be impacted by this level and it doesn't add enough
// extra value for our team over the debug level.
//            case .verbose:
//                return "verbose"
            }
        }
    }
}
