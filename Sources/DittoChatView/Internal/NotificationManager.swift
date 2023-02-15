//
//  NotificationManager.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import UIKit

@available(iOS 15.0, *)
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()

        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Ditto Chat: notification request granted - \(granted)")
        }

        notificationCenter.delegate = self
    }

    func showNotification(newMessage: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = newMessage
        let request = UNNotificationRequest(identifier: "DittoChatMessages", content: content, trigger: nil)
        notificationCenter.add(request)
    }

    // UNUserNotificationCenterDelegate methods
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
