//
//  Copyright © 2026 DittoLive Incorporated. All rights reserved.
//

import Foundation

/// URLs into the bundled presence-viewer web assets. The JS/HTML/CSS lives
/// under `Resources/dist/`; `index.html` loads its sibling assets via relative
/// paths so consumers only need the directory URL.
public enum DittoPresenceViewerResources {
    public static let htmlURL: URL = {
        guard let url = Bundle.module.url(forResource: "index", withExtension: "html", subdirectory: "dist") else {
            fatalError("DittoPresenceViewerCore: dist/index.html missing from bundle")
        }
        return url
    }()

    public static let webDistDirURL: URL = htmlURL.deletingLastPathComponent()
}
