 # DittoSwiftTools
 <img align="left" src="/Img/Ditto_logo.png" alt="Ditto Logo" width="150">  
 <br />  
 <br />  
 <br />  
 
DittoSwiftTools are diagnostic tools for Ditto. You can view connected peers, export debug logs, browse collections/documents and see Ditto's disk usage.

## Requirements
* iOS 15.0+
* Swift 5.0+

## Installation
The reccomended approach to use DittoSwiftTools in your project is using the Swift Package Manager.
1. With your project open in Xcode go to File -> Add Packages, then search using  "github.com/getditto/DittoSwiftTools" to find the DittoSwiftTools package.  

 <img src="/Img/addPackage.png" alt="Add Package Image">  

2. Select "Add Package"
3. Select which DittoSwiftTools products you would like, then select "Add Package"

## Usage
There are four targets in this package: Presence Viewer, Data Browser, Export Logs, Disk Usage.

### 1. Presence Viewer
The Presence Viewer displays a mesh graph that allows you to see all connected peers within the mesh and the transport that each peer is using to make a connection.  

 <img src="/Img/presenceViewer.png" alt="Presence Viewer Image" width="300">  

First, make sure the "DittoPresenceViewer" was added to your Target.
Then, use `import DittoPresenceViewer` to import the Presence Viewer

You can use the Presence Viewer in SiwftUI or UIKit

**SwiftUI**  
Use `PresenceView(ditto: Ditto)` and pass in your Ditto instance to display the mesh graph.
```
import DittoPresenceViewer

struct PresenceViewer: View{

    var body: some View {
        PresenceView(ditto: DittoManager.shared.ditto)
    }
}
```

**UIKit**  
Call [present](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621380-present) and pass `DittoPresenceView(ditto: DittoManager.shared.ditto).viewController` as a parameter. Set `animated` to `true`
```
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    present(DittoPresenceView(ditto: DittoManager.shared.ditto).viewController, animated: true) {
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }
}
```

### 2. Data Browser
The Ditto Data Browser allows you to view all your collections, documents within each collection and the propeties/values of a document. With the Data Browser, you can observe any changes that are made to your collections and documents in real time.  

 <img src="/Img/collections.png" alt="Collections Image" width="300">  

 <img src="/Img/document.png" alt="Document Image" width="300">  

First, make sure the "DittoDataBrowser" was added to your Target.
Then, use `import DittoDataBrowser` to import the Data Browser.

**SwiftUI**  
Use `DataBrowser(ditto: Ditto)` and pass in your Ditto instance to display the Data Browser.
```
import DittoDataBrowser

struct DataBrowserView: View {
    var body: some View {
       DataBrowser(ditto: DittoManager.shared.ditto)
    }
}
```

### 3. Export Logs
Export Logs allows you to export a file of the logs from your applcation.  

 <img src="/Img/exportLogs.png" alt="Export Logs Image" width="300">  

First, make sure the "DittoExportLogs" was added to your Target.
Then, use `import DittoExportLogs` to import the Export Logs.

**SwiftUI**  
Use `ExportLogs()` to export the logs. It is reccomended to call `ExportLogs` from within a [sheet](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:)).
```
.sheet(isPresented: $exportLogst) {
    ExportLogs()
}
```

### 4. Disk Usage
Disk Usage allows you to see Ditto's file space usage.  

 <img src="/Img/diskUsage.png" alt="Disk Usage Image" width="300">  

First, make sure the "DittoDiskUsage" was added to your Target.
Then, use `import DittoDiskUsage` to import the Disk Usage.

**SwiftUI**  
use `DittoDiskUsageView(ditto: Ditto)` and pass in your Ditto instance.
```
import DittoDiskUsage

struct DiskUsageViewer: View {
    var body: some View {
        DittoDiskUsageView(ditto: DittoManager.shared.ditto)
    }
}
```

## Contact
* [Contact Us](https://www.ditto.live/about/contact)

## License (MIT)
Copyright © 2023 DittoLive

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
