//
//  AlarmUserNotification.swift
//  curbmap
//
//  Created by Eli Selkin on 12/29/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import UserNotifications
import RxSwift

class AlarmUserNotification: NSObject, UNUserNotificationCenterDelegate {
    var timer: Timer!
    var timerController: AlarmViewController!
    var timerValue: Int = 0
    private var _timerAllotted = PublishSubject<Int>()
    var timerAllotted: Observable<Int>?
    @objc func trigger_TimerAllottedUpdate(newtimerValue: Int) {
        _timerAllotted.onNext(newtimerValue)
        print("trigger called")
    }
    var timerIsRunning = Variable(false)

    
    override init () {
        super.init()
        timerAllotted = _timerAllotted.share(replay: 1, scope: .forever)
        trigger_TimerAllottedUpdate(newtimerValue: 0)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch(response.actionIdentifier) {
        case UNNotificationDismissActionIdentifier:
            break
        case UNNotificationDefaultActionIdentifier:
            break
        case "Snooze":
            break
        default:
            break;
        }
        completionHandler()
    }

    func gotPendingNotification(pending:[UNNotificationRequest]) {
        if (timerController != nil) {
            if (pending.count > 0) {
                for pendingNotification in pending {
                    if (pendingNotification.identifier == "CurbmapAlarmLocalNotification") {
                        print("got notification")
                        let dateString = pendingNotification.content.body.split(separator: ":")[1].trimmingCharacters(in: [" "])
                        let date = Date(timeIntervalSince1970: Double(dateString)!)
                        print("date: \(String(describing: date))")
                        let currentDate = Date()
                        let calendar = Calendar.current
                        if (currentDate < date) {
                            print("current date less than ")
                            // set up a new timer and start updating it
                            let dateComponents = calendar.dateComponents(Set<Calendar.Component>([ .second]), from: currentDate, to: date)
                            self.timerValue = Int((dateComponents.second)!)
                            DispatchQueue.main.async {
                                self.timerController.startTimer()
                            }
                        }
                    }
                }
            }
        }
    }
}
