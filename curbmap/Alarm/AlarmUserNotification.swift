//
//  AlarmUserNotification.swift
//  curbmap
//
//  Created by Eli Selkin on 12/29/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import UserNotifications
import ReactiveSwift
import ReactiveCocoa

class AlarmUserNotification: NSObject, UNUserNotificationCenterDelegate {
    var timer: Timer!
    var timerController: AlarmViewController!
    var timerValue: Int = 0
    var timerString = MutableProperty<String>("")
    var timerIsRunning: Bool
    override init () {
        timerIsRunning = false
        super.init()
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
                        let currentDate = Date()
                        let calendar = Calendar.current
                        if (currentDate < date) {
                            // set up a new timer and start updating it
                            let dateComponents = calendar.dateComponents(Set<Calendar.Component>([ .second]), from: currentDate, to: date)
                            self.timerValue = Int((dateComponents.second)!)
                            DispatchQueue.main.async {
                                if (self.timer == nil) {
                                    self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.countDown), userInfo: nil, repeats: true)
                                }
                                self.timerController.timerLabel.reactive.text <~ self.timerString
                                self.timerController.picker.isHidden = true
                                self.timerController.timerLabel.isHidden = false
                                self.timerController.startButton.setTitle("Cancel timer", for: .normal)
                                self.timerIsRunning = true
                            }
                        }
                    }
                }
            }
        }
    }
    @objc func countDown() {
        self.timerValue -= 1
        self.setRemainingTime(self.timerValue)
        if (self.timerValue <= 0) {
            self.timer.invalidate()
            self.timer = nil
            self.timerController.timerLabel.text = "Move your car now :-)"
            self.timerController.timerLabel.adjustsFontSizeToFitWidth = true
            self.timerController.timerLabel.numberOfLines = 0
            self.timerController.timerLabel.textAlignment = .center
         }
    }
    @objc func setRemainingTime(_ timeRemaining: Int) {        
        let hours = Int(Double(timeRemaining) / 3600)
        let minutes = Int(Double(timeRemaining).truncatingRemainder(dividingBy: 3600.0)/60)
        let seconds = Int(Double(timeRemaining).truncatingRemainder(dividingBy: 3600.0).truncatingRemainder(dividingBy: 60.0))
        self.timerString.swap(String(format:"%02d : %02d : %02d", hours, minutes, seconds))
    }
    
}
