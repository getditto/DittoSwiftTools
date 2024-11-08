import DittoSwift

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

@available(tvOS, unavailable)
public struct ExportLogs: UIViewControllerRepresentable {
    
    @Binding var activityViewController: UIActivityViewController?
    
    public init(activityViewController: Binding<UIActivityViewController?>) {
        self._activityViewController = activityViewController
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        // Create a dummy UIViewController to host the UIActivityViewController later
        let viewController = UIViewController()
        
        Task {
            if let zippedLogs = await getZippedLogs() {
                let avc = UIActivityViewController(activityItems: [zippedLogs], applicationActivities: nil)
                avc.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]
                
                DispatchQueue.main.async {
                    self.activityViewController = avc
                }
            }
        }
        
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Present the activity view controller if it’s available
        if let avc = activityViewController, uiViewController.presentedViewController == nil {
            uiViewController.present(avc, animated: true)
        }
    }
    
    func getZippedLogs() async -> URL? {
        do {
            return try await LogManager.shared.exportLogs()
        } catch {
            print("Error exporting logs")
            return nil
        }
    }
}


