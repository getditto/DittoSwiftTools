import DittoSwift

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif


@available(iOS 13.0, *)
public struct ExportLogs: UIViewControllerRepresentable {
    
    public init() {}

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        
        let zippedLogs = getZippedLogs()
        
        let avc = UIActivityViewController(activityItems: [zippedLogs as Any], applicationActivities: nil)
        avc.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]
        
        return avc
    }
    

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
    
    
    func getZippedLogs() -> URL? {
        if let logFileURL = DittoLogManager.shared.logFileURL {
            DittoLogger.setLogFileURL(logFileURL)
        }
        
        guard let zippedLogs = DittoLogManager.shared.createLogsZip() else {
            assertionFailure(); return nil
        }
        
        return zippedLogs
    }
    
}


