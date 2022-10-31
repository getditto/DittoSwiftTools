//
//  Copyright © 2019 Hamilton Chapman. All rights reserved.
//

import UIKit

private var lastOnMain = Date()
private var foregrounded = true
private var backgroundMonitor: BackgroundThread?

func startMainThreadBlockingMonitor() {
    mainPulse()
    backgroundMonitor = BackgroundThread()
    backgroundMonitor?.start()
}

private func mainPulse() {
    lastOnMain = Date()
    foregrounded = UIApplication.shared.applicationState == .active
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
        mainPulse()
    }
}

private class BackgroundThread: Thread {
    var lastObservedFromBackground = Date()
    var sameCount = 0

    override func main() {
        Thread.setThreadPriority(1.0)
        while true {
            if foregrounded {
                if lastObservedFromBackground == lastOnMain {
                    sameCount += 1
                    if sameCount > 1 {
                        let delay = -lastOnMain.timeIntervalSinceNow
                        print("It has been \(delay) seconds since monitor ran on main thread. Check thread " +
                              "1 for deadlock.")
                        try! crash()
                    }
                } else {
                    sameCount = 0
                }
                lastObservedFromBackground = lastOnMain
            }
            Thread.sleep(forTimeInterval: 0.3)
        }
    }

    func crash() throws {
        enum MainThreadMonitorError: Error {
            case timeout
        }
        throw MainThreadMonitorError.timeout
    }
}
