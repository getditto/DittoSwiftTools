import DittoSwift

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif


@available(iOS 13.0, *)
public struct ExportData: UIViewControllerRepresentable {

    private let ditto: Ditto
    private let fileManager: FileManager

    public init(ditto: Ditto, fileManager: FileManager = FileManager.default) {
        self.ditto = ditto
        self.fileManager = fileManager
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {

        let zippedURL = zipDittoDirectory()

        let avc = UIActivityViewController(activityItems: [zippedURL as Any], applicationActivities: nil)
        avc.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]

        return avc
    }

    private func zipDittoDirectory() -> URL? {

        let destinationURL = fileManager.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).zip")

        try? FileManager().removeItem(at: destinationURL)

        var nsError: NSError?

        NSFileCoordinator().coordinate(readingItemAt: self.ditto.persistenceDirectory,
                                       options: [.forUploading], error: &nsError) { tempURL in
            do {
                try FileManager().moveItem(at: tempURL, to: destinationURL)
            } catch {
                assertionFailure("Ditto directory zipping failed.")
            }
        }

        if let error = nsError {
            assertionFailure("Ditto directory zipping failed. \(error.localizedDescription)")
            return nil

        }

        return destinationURL
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Do nothing
    }
}
