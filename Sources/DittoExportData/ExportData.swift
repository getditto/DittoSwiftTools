import DittoSwift

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

public struct ExportData: View {

    private let ditto: Ditto
    private let fileManager: FileManager

    public init(ditto: Ditto, fileManager: FileManager = FileManager.default) {
        self.ditto = ditto
        self.fileManager = fileManager
    }

    public var body: some View {
        #if os(iOS)
        ExportDataIOS(ditto: ditto, fileManager: fileManager)
        #endif
    }
}

// MARK: - iOS Implementation
#if os(iOS)
struct ExportDataIOS: UIViewControllerRepresentable {
    
    let ditto: Ditto
    let fileManager: FileManager

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any]
        if let zippedURL = zipDittoDirectory() {
            activityItems = [zippedURL]
        } else {
            // Zipping failed; present an empty share sheet rather than crashing.
            activityItems = []
        }

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo, .addToReadingList, .assignToContact, .openInIBooks]

        return activityViewController
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

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Do nothing
    }
}
#endif


// MARK: - macOS Implementation
#if os(macOS)
/// Exports the Ditto store directory through the macOS sharing picker.
public struct ExportDataMacOS {
    
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

/// The name published by earlier DittoSwiftTools releases. Existing callers
/// can continue to compile while new code uses the standard Swift spelling,
/// `ExportDataMacOS`.
@available(*, deprecated, renamed: "ExportDataMacOS")
public typealias ExportData_macOS = ExportDataMacOS
#endif
