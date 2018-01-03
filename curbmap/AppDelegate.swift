//
//  AppDelegate.swift
//  curbmap
//
//  Created by Eli Selkin on 11/23/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import KeychainAccess
import UserNotifications
import AudioToolbox
import AVFoundation
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioPlayerDelegate {
    let user: User = User(username: "curbmaptest", password: "TestCurbm@p1")
    let keychain = Keychain(service: "com.curbmap.keys")
    let notificationDelegate = AlarmUserNotification()
    var mapController: MapViewController!
    var settingsController: SettingsViewController!
    var token: String!
    var window: UIWindow?
    var windowLocation = 0;
    var error : Error!
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound];
    var localNotificationsAllowed : Bool = false
    var remoteNotificationsAllowed: Bool = false
    var registeredForLocal : Bool = false
    var registeredForRemote: Bool = false
    let realm = try! Realm()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        center.delegate = notificationDelegate
        registerForPushNotifications()
        registerForLocalNotifications()
        center.getPendingNotificationRequests(completionHandler: notificationDelegate.gotPendingNotification)
        self.getUser()
        return true
    }
    func registerForLocalNotifications() {
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
                if (self.settingsController != nil) {
                    self.settingsController.checkStatus()
                }
            }
        }
        self.getLocalNotificationSettings()
    }
    func registerForPushNotifications() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    func getLocalNotificationSettings() {
        center.getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else { return }
            self.localNotificationsAllowed = true
            self.registeredForLocal = true
            if (self.settingsController != nil) {
                self.settingsController.checkStatus()
            }
        }
    }
    func getNotificationSettings() {
        center.getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.sync {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        self.token = tokenParts.joined()
        self.remoteNotificationsAllowed = true
        self.registeredForRemote = true
    }
    
    @objc func removeNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: ["CurbmapAlarmLocalNotification"])
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
    @objc func getUser() {
        do {
            let username_token = try keychain.get("user_curbmap")
            if (username_token != nil) {
                let password_token = try keychain.get("pass_curbmap")
                if (password_token != nil) {
                    user.set_username(username: username_token!)
                    user.set_password(password: password_token!)
                    user.set_remember(remember: true)
                    user.login(callback: self.finishedLogin)
                }
            }
        } catch _ {
            print("cannot get username")
        }
    }
    
    @objc func setSetting(setting: String, value: String) {
        let settings = realm.objects(Settings.self)
        if (settings.count > 0) {
            try! realm.write {
                switch(setting) {
                case "mapstyle":
                    settings[0].mapstyle = value
                    break
                case "follow":
                    settings[0].follow = value
                    break
                case "push":
                    settings[0].push = value
                    break
                case "units":
                    settings[0].units = value
                    break
                case "offline":
                    settings[0].offline = value
                    break
                default:
                    break
                }
            }
        }
    }
    
    @objc func getSettings() {
        let settings = realm.objects(Settings.self)
        if (settings.count > 0) {
            self.user.settings.updateValue(settings[0].mapstyle, forKey: "mapstyle")
            if (self.mapController != nil) {
                self.mapController.changeStyle(style: settings[0].mapstyle)
            }
            self.user.settings.updateValue(settings[0].follow, forKey: "follow")
            if (self.mapController != nil) {
                self.mapController.trackUser = false
            }
            self.user.settings.updateValue(settings[0].push, forKey: "push")
            if (settings[0].push == "n") {
                self.localNotificationsAllowed = false
                self.remoteNotificationsAllowed = false
            }
            self.user.settings.updateValue(settings[0].units, forKey: "units")
            
            self.user.settings.updateValue(settings[0].offline, forKey: "offline")
            if (mapController != nil){
                self.mapController.changeOffline(offline: settings[0].offline)
            }
        } else {
            let newSettings = Settings()
            try! realm.write {
                realm.add(newSettings)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }
    @objc func changePushStatus(status: String) {
        // we can only give them what they've authorized
        registerForPushNotifications()
        registerForLocalNotifications()
    }
    @objc func finishedLogin(_ result: Int) {
        if (result == 1) {
            print("Successfully logged in")
        } else {
            if (result == 0) {
                print("Incorrect password")
            } else if (result == -1) {
                print("Not authenticated!")
            } else if (result == -2) {
                print("No such user")
            }
        }
    }
    func setCoachMarksComplete(inView: String, completed: Bool) {
        let coachMarksStatus = realm.objects(CoachMarksStatus.self)
        if (coachMarksStatus.count > 0) {
            try! realm.write {
                switch (inView) {
                case "map":
                    coachMarksStatus[0].map = completed
                    break
                case "alarm":
                    coachMarksStatus[0].alarm = completed
                    break
                case "login":
                    coachMarksStatus[0].login = completed
                    break
                case "signup":
                    coachMarksStatus[0].signup = completed
                    break
                case "settings":
                    coachMarksStatus[0].settings = completed
                    break
                default:
                    break
                }
            }
        } else {
            var newCoachMarksStatus = CoachMarksStatus()
            switch (inView) {
            case "map":
                newCoachMarksStatus.map = completed
                break
            case "alarm":
                newCoachMarksStatus.alarm = completed
                break
            case "login":
                newCoachMarksStatus.login = completed
                break
            case "signup":
                newCoachMarksStatus.signup = completed
                break
            case "settings":
                newCoachMarksStatus.settings = completed
                break
            default:
                break
            }
            try! realm.write {
                realm.add(newCoachMarksStatus)
            }
        }
    }
    func getCoachMarksComplete(inView: String) -> Bool {
        let coachMarksStatus = realm.objects(CoachMarksStatus.self)
        if (coachMarksStatus.count > 0) {
            switch (inView) {
            case "map":
                return coachMarksStatus[0].map
            case "alarm":
                return coachMarksStatus[0].alarm
            case "login":
                return coachMarksStatus[0].login
            case "signup":
                return coachMarksStatus[0].signup
            case "settings":
                return coachMarksStatus[0].settings
            default:
                break
            }
        }
        return false
    }
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

class Settings : Object {
    @objc dynamic var mapstyle: String = "d"
    @objc dynamic var units: String = "mi"
    @objc dynamic var push: String = "n"
    @objc dynamic var follow: String = "y"
    @objc dynamic var offline: String = "n"
}

class CoachMarksStatus: Object {
    @objc dynamic var map: Bool = false
    @objc dynamic var login: Bool = false
    @objc dynamic var signup: Bool = false
    @objc dynamic var settings: Bool = false
    @objc dynamic var alarm: Bool = false
}
