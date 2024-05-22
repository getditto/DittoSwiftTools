//
//  Copyright © 2021 DittoLive Incorporated. All rights reserved.
//

import UIKit
import CoreBluetooth

// MARK: - AuthorizationStatus

/// Each sub-component has its own strongly typed authorization status
/// and includes a few kinds of authorization we're not overly concerned
/// with. We define a simpler category here which corresponds to the
/// major decisions our app needs to take.
enum AuthorizationStatus: CaseIterable, Equatable, Hashable {
    case authorized
    case denied
    case notDetermined
}

extension AuthorizationStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .notDetermined:
            return "not yet requested"
        }
    }
}

// MARK: - AuthorizationsManager

/// A singleton which offers a convenient single point for interacting
/// with the various user authorizations we might need (notifications,
/// bluetooth, etc.)
///
/// We unfortunately can't seem to (easily) check for local network
/// authorization.
class AuthorizationsManager {

    // MARK: - Properties

    var bleAuthorizationStatus: AuthorizationStatus {
        switch CBCentralManager.authorization {
        case .allowedAlways:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .denied
        case .denied:
            return .denied
        @unknown default:
            print("WARNING: Unknown CBCentralManager status")
            return .notDetermined
        }
    }

    var localNotificationAuthorizationStatus: AuthorizationStatus {
        var status = AuthorizationStatus.notDetermined
        // Such a hack. Look away.
        let semaphore = DispatchSemaphore(value: 0)

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                status = .notDetermined
            case .denied:
                status = .denied
            case .authorized:
                 status = .authorized
            case .ephemeral:
                status = .authorized
            case .provisional:
                status = .authorized
            @unknown default:
                print("WARNING: Unknown UNUserNotificationCenter status")
                status = .notDetermined
            }
            semaphore.signal()
        }

        _ = semaphore.wait(wallTimeout: .distantFuture)
        return status
    }

    // MARK: - Singleton

    /// Singleton instance. All access is via `AuthorizationsManager.shared`.
    static var shared = AuthorizationsManager()

    // MARK: - Private Constructor

    private init() {}

    // MARK: - Functions

    func requestNotificationAuthorization() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if !granted {
                print("Request for user notifications authorization was denied")
            }
            if let error = error {
                print("Request for user notifications authorization failed with error \(error)")
            }
        }
    }

}
