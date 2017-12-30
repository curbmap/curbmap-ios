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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioPlayerDelegate {
    let user: User = User(username: "curbmaptest", password: "TestCurbm@p1")
    let keychain = Keychain(service: "com.curbmap.keys")
    let notificationDelegate = AlarmUserNotification()
    var mapController: MapViewController!
    var token: String!
    var window: UIWindow?
    var windowLocation = 0;
    var error : Error!
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound];
    var localNotificationsAllowed : Bool = false
    var remoteNotificationsAllowed: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        registerForPushNotifications()
        registerForLocalNotifications()
        center.delegate = notificationDelegate
        center.getPendingNotificationRequests(completionHandler: notificationDelegate.gotPendingNotification)
        return true
    }
    func registerForLocalNotifications() {
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Something went wrong")
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
        }
    }
    func getNotificationSettings() {
        center.getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        self.token = tokenParts.joined()
        self.remoteNotificationsAllowed = true
    }
    
    @objc func removeNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: ["CurbmapAlarmLocalNotification"])
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
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
            let mapstyle = try! keychain.get("settings_mapstyle")
            if (mapstyle != nil) {
                self.user.settings.updateValue(mapstyle!, forKey: "mapstyle")
                if (self.mapController != nil) {
                    self.mapController.changeStyle(style: mapstyle!)
                }
            }
            
            let follow = try! keychain.get("settings_follow")
            if (follow != nil) {
                self.user.settings.updateValue(follow!, forKey: "follow")
                if (self.mapController != nil) {
                    self.mapController.trackUser = false
                }
            }
            
            let push = try! keychain.get("settings_push")
            if (push != nil) {
                self.user.settings.updateValue(push!, forKey: "push")
            }
            
            let units = try! keychain.get("settings_units")
            if (units != nil) {
                self.user.settings.updateValue(units!, forKey: "units")
            }
            
            let offline = try! keychain.get("settings_offline")
            if (offline != nil) {
                self.user.settings.updateValue(offline!, forKey: "offline")
                self.mapController.changeOffline(offline: offline!)
            }
        } catch _ {
            print("cannot get username")
        }
    }
    @objc func changePushStatus(status: String) {
        
    }
    @objc func finishedLogin() {
        print("finished login")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

