//
//  LocalPushNotifications.swift
//  explorar
//
//  Created by Fabian Kuschke on 17.08.25.
//

import UserNotifications
import UIKit
import TelemetryClient

final class LocalNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifications()
    private override init() {
        super.init()
        TelemetryDeck.signal("sendLocalNotification")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if granted {
                        print("Notification granted.")
                    } else {
                        print("Notification permission denied.")
                    }
                }
            } else {
                print("Notification permission denied!")
            }
        }
    }
    
    func scheduleIn(minutes: Int, title: String, body: String) {
        let id = UUID().uuidString
        let secs = max(1, minutes * 60)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(secs), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error notification: \(error)")
            }else {
                print("Notification scheduled in \(minutes) min successfully")
            }
        }
    }
    func scheduleIn(seconds: Int, title: String, body: String) {
        let id = UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:TimeInterval(seconds), repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error notification: \(error)")
            }else {
                print("Notification scheduled in \(seconds) sec successfully")
            }
        }
    }
    
    func scheduleOn(date: Date, title: String, body: String){
        
        let id = UUID().uuidString
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error notification: \(error)")
            }else {
                print("Notification scheduled on \(date) successfully")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

