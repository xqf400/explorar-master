//
//  explorarApp.swift
//  explorar
//
//  Created by Fabian Kuschke on 18.07.25.
//

import FirebaseCore
import SwiftUI
import TelemetryClient
import UserNotifications
import OneSignalFramework

@main
struct explorarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var contentID: String? = nil
    
    init() {
        FirebaseApp.configure()
        let config = TelemetryDeck.Config(appID: telemetryKey)
        config.testMode = false
        TelemetryDeck.initialize(config: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(contentID: $contentID)
                .environmentObject(viewModel)
                .onOpenURL { url in
                    print("URL11: \(url)")
                    parse(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    if let url = userActivity.webpageURL {
                        print("URL12: \(url)")
                        parse(url: url)
                    }
                }
                .onAppear {
                    TelemetryDeck.signal("newSasion")
                    DeepLinkTester.triggerIfPresent { url in
                        parse(url: url)
                    }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                print("background")
                SharedPlaces.shared.locationManager.stopUpdatingLocation()
                if isInTestMode {
                    LocalNotifications.shared.scheduleIn(seconds: 5, title: "Hey \(UserFire.shared.userFirebase?.userName ?? "")", body: NSLocalizedString("Komm zurück, es warten noch weitere Sehenswürdigkeiten auf dich!", comment: ""))
                }
            case .active:
                print("scene active")
            default: break
            }
        }
    }
    func parse(url: URL) {
        print("URL13: \(url)")
        if let c = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let id = c.queryItems?.first(where: { $0.name == "id" })?.value {
            contentID = id
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        // not working
        print("background")
    }
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("appdelegate")
        if let stored = UserDefaults.standard.object(forKey: "isInTestMode") as? Bool {
            isInTestMode = stored
            print("Testmode: \(stored)")
        }
        UNUserNotificationCenter.current().delegate = self
        
        OneSignal.initialize(oneSignalID, withLaunchOptions: launchOptions)
        
        OneSignal.Notifications.requestPermission({ accepted in
            print("OneSignal permission accepted: \(accepted)")
        }, fallbackToSettings: true)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    
                }
            }
        }
        return true
    }
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        print(userInfo)
        
        return [[.banner, .sound, .badge]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
    }
    
}

import Foundation
import UIKit

enum DeepLinkTester {
    static func triggerIfPresent(_ handler: @escaping (URL) -> Void) {
#if DEBUG
        if let url = readURLFromLaunchArguments() ?? readURLFromEnv() {
            DispatchQueue.main.async { handler(url) }
        }
#endif
    }
    
    private static func readURLFromLaunchArguments() -> URL? {
        print("url readURLFromLaunchArguments")
        let args = ProcessInfo.processInfo.arguments
        
        if let merged = args.first(where: { $0.hasPrefix("-deeplink=") }) {
            let s = String(merged.dropFirst("-deeplink=".count))
            return URL(string: s)
        }
        
        if let i = args.firstIndex(of: "-deeplink"), i + 1 < args.count {
            return URL(string: args[i + 1])
        }
        
        return nil
    }
    
    private static func readURLFromEnv() -> URL? {
        print("url readURLFromEnv")
        if let s = ProcessInfo.processInfo.environment["DEEPLINK_URL"] {
            return URL(string: s)
        }
        return nil
    }
}
