//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit
import UserNotifications

class NotificationManager: NSObject, NotificationManagerProtocol {
    private let notificationCenter: UserNotificationCenterProtocol
    private let clientProxy: ClientProxyProtocol

    init(clientProxy: ClientProxyProtocol, notificationCenter: UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.clientProxy = clientProxy
        self.notificationCenter = notificationCenter
        super.init()
    }

    // MARK: NotificationManagerProtocol

    weak var delegate: NotificationManagerDelegate?

    var isAvailable: Bool {
        true
    }

    func start() {
        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
                                                        title: ElementL10n.actionQuickReply,
                                                        options: [])
        let replyCategory = UNNotificationCategory(identifier: NotificationConstants.Category.reply,
                                                   actions: [replyAction],
                                                   intentIdentifiers: [],
                                                   options: [])
        notificationCenter.setNotificationCategories([replyCategory])
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard let self else {
                return
            }
            if let error {
                MXLog.debug("[NotificationManager] request authorization failed: \(error)")
            } else {
                MXLog.debug("[NotificationManager] permission granted: \(granted)")
                DispatchQueue.main.async {
                    self.delegate?.authorizationStatusUpdated(self, granted: granted)
                }
            }
        }
    }

    func register(with deviceToken: Data, completion: ((Bool) -> Void)? = nil) {
        setPusher(with: deviceToken,
                  clientProxy: clientProxy,
                  completion: completion)
    }

    func registrationFailed(with error: Error) { }

    func showLocalNotification(with title: String, subtitle: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle {
            content.subtitle = subtitle
        }
        let request = UNNotificationRequest(identifier: ProcessInfo.processInfo.globallyUniqueString,
                                            content: content,
                                            trigger: nil)
        notificationCenter.add(request) { error in
            if let error {
                MXLog.debug("[NotificationManager] show local notification failed: \(error)")
            } else {
                MXLog.debug("[NotificationManager] show local notification succeeded")
            }
        }
    }

    private func setPusher(with deviceToken: Data,
                           clientProxy: ClientProxyProtocol,
                           completion: ((Bool) -> Void)?) {
        Task {
            do {
                try await clientProxy.setPusher(pushkey: deviceToken.base64EncodedString(),
                                                kind: .http,
                                                appId: ServiceLocator.shared.settings.pusherAppId,
                                                appDisplayName: "\(InfoPlistReader.target.bundleDisplayName) (iOS)",
                                                deviceDisplayName: UIDevice.current.name,
                                                profileTag: pusherProfileTag(),
                                                lang: Bundle.preferredLanguages.first ?? "en",
                                                url: ServiceLocator.shared.settings.pushGatewayBaseURL.absoluteString,
                                                format: .eventIdOnly,
                                                defaultPayload: [
                                                    "aps": [
                                                        "mutable-content": 1,
                                                        "alert": [
                                                            "loc-key": "Notification",
                                                            "loc-args": []
                                                        ]
                                                    ]
                                                ])
                MXLog.debug("[NotificationManager] set pusher succeeded")
                completion?(true)
            } catch {
                MXLog.debug("[NotificationManager] set pusher failed: \(error)")
                completion?(false)
            }
        }
    }

    private func pusherProfileTag() -> String {
        if let currentTag = ServiceLocator.shared.settings.pusherProfileTag {
            return currentTag
        }
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let newTag = (0..<16).map { _ in
            let offset = Int.random(in: 0..<chars.count)
            return String(chars[chars.index(chars.startIndex, offsetBy: offset)])
        }.joined()

        ServiceLocator.shared.settings.pusherProfileTag = newTag
        return newTag
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard ServiceLocator.shared.settings.enableInAppNotifications else {
            return []
        }
        guard let delegate else {
            return [.badge, .sound, .list, .banner]
        }

        guard delegate.shouldDisplayInAppNotification(self, content: notification.request.content) else {
            return []
        }

        return [.badge, .sound, .list, .banner]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case NotificationConstants.Action.inlineReply:
            guard let response = response as? UNTextInputNotificationResponse else {
                return
            }
            await delegate?.handleInlineReply(self,
                                              content: response.notification.request.content,
                                              replyText: response.userText)
        case UNNotificationDefaultActionIdentifier:
            await delegate?.notificationTapped(self,
                                               content: response.notification.request.content)
        default:
            break
        }
    }
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol { }
