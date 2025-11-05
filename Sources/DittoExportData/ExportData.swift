import DittoSwift

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

@available(tvOS, unavailable)
public struct ExportData: View {

    private let ditto: Ditto
    private let fileManager: FileManager

    public init(ditto: Ditto, fileManager: FileManager = FileManager.default) {
        self.ditto = ditto
        self.fileManager = fileManager
    }

    public var body: some View {
        #if os(iOS)
        ExportData_iOS(ditto: ditto, fileManager: fileManager)
        #endif
    }
}

// MARK: - iOS Implementation
#if os(iOS)
struct ExportData_iOS: UIViewControllerRepresentable {
    
    let ditto: Ditto
    let fileManager: FileManager

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let zippedURL = zipDittoDirectory()

        let activityViewController = UIActivityViewController(activityItems: [zippedURL as Any], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]

        return activityViewController
    }

    private func zipDittoDirectory() -> URL? {
        let destinationURL = fileManager.temporaryDirectory.appendingPathComponent("DittoData.zip")

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

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Do nothing
    }
}
#endif


// MARK: - macOS Implementation
#if os(macOS)
public struct ExportData_macOS {
    
    let ditto: Ditto
    let fileManager: FileManager

    public init(ditto: Ditto, fileManager: FileManager = FileManager.default) {
        self.ditto = ditto
        self.fileManager = fileManager
    }

    public func export() {
        DispatchQueue.main.async {
            presentSharingPicker()
        }
    }

    private func presentSharingPicker() {
        guard let zippedURL = zipDittoDirectory() else { return }

        let sharingServicePicker = NSSharingServicePicker(items: [zippedURL])
        if let window = NSApplication.shared.keyWindow {
            sharingServicePicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }

    private func zipDittoDirectory() -> URL? {
        let destinationURL = fileManager.temporaryDirectory.appendingPathComponent("DittoData.zip")

        try? FileManager().removeItem(at: destinationURL)

        var nsError: NSError?

        NSFileCoordinator().coordinate(readingItemAt: self.ditto.absolutePersistenceDirectory,
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
}
#endif


