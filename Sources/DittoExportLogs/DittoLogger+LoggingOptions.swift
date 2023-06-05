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
//            case .verbose:
//                return "verbose"
            }
        }
    }
}
