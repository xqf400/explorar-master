//
//  SendMessage.swift
//  explorar
//
//  Created by Fabian Kuschke on 28.07.25.
//

import SwiftUI

public struct SendMessage: View {
    
    public var body: some View {
        VStack {
            Spacer()
            Text("Send Message")
            Spacer()
            Button("Send 1 message to XQF") {
                FirestoreService.shared.sendOneSignalNotification(toUsername: "XQF", title: "Titel", message: "Test")
            }
            Spacer()
            Button("Send to all message") {
                FirestoreService.shared.sendOneSignalNotificationToAllUsers(title: "Titel", message: "Testen")
            }
            Spacer()
            Button("Send to all with name") {
                FirestoreService.shared.sendPersonalizedNotificationToAllUsers( message: "Es gibt neue Orte zu entdecken! Check die App und siehe, was es Neues gibt!")
            }
            Spacer()
            Button("Send local notification") {
                FirestoreService.shared.sendLocalNotification(title: "Titel", message: "test", delaySeconds: 10)
            }
            Spacer()
        }.onAppear {
            
        }
    }
}
