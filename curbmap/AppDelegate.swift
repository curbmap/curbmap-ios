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
import Alamofire
import Photos
import OpenLocationCode

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AVAudioPlayerDelegate {
    let user: User = User(username: "curbmaptest", password: "TestCurbm@p1")
    let keychain = Keychain(service: "com.curbmap.keys")
    let notificationDelegate = AlarmUserNotification()
    var mapController: MapViewController!
    var settingsController: SettingsViewController!
    var token: String!
    var window: UIWindow?
    var windowLocation = 1;
    var error : Error!
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound];
    var localNotificationsAllowed : Bool = false
    var remoteNotificationsAllowed: Bool = false
    var registeredForLocal : Bool = false
    var registeredForRemote: Bool = false
    let realm = try! Realm()
    var restrictions: [Restriction] = []
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
    
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
    
    func addRestriction(_ restriction: Restriction) {
        self.restrictions.append(restriction)
    }
    
    func restrictionsToAdd() -> [Restriction] {
        return self.restrictions
    }
    func popRestriction() -> Restriction? {
        return self.restrictions.popLast()
    }
    
    func submitRestrictions() -> Bool {
        // store all restrictions to Realm
        var line: [[Double]] = []
        var lineString = ""
        for i in 0..<self.mapController.line.count {
            line.append([self.mapController.line[i].coordinate.longitude, self.mapController.line[i].coordinate.latitude])
            lineString += String(self.mapController.line[i].coordinate.longitude) + "," + String(self.mapController.line[i].coordinate.latitude) + ","
        }
        let lineStringEnd = lineString.index(lineString.startIndex, offsetBy: lineString.count-1)
        lineString = String(lineString[lineString.startIndex..<lineStringEnd]) // not including last ,
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "session": self.user.get_session(),
            ]

        var restrParams: [[String: Any]] = []
        for r in restrictions {
            restrParams.append(r.asDictionary())
        }
        let parameters: Parameters = ["line": line,
                          "restrictions": restrParams]
        if (NetworkReachabilityManager()?.isReachableOnEthernetOrWiFi)! || (self.user.settings["offline"] == "n") {
            Alamofire.request("https://curbmap.com:50003/addLine", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { [weak self] response in
                guard self != nil else { return }
                if var json = response.result.value as? [String: Any] {
                    if let success = json["success"] as? Int {
                        if (success == 1) {
                            // put restrictions in realm as complete
                            self?.storeRestrsInRealm(true, json["line_id"] as? String, lineString)
                            self?.mapController.cancelLine(self?.mapController)
                        } else {
                            // put the restrictions in realm for later
                            self?.storeRestrsInRealm(false, nil, lineString)
                            self?.mapController.cancelLine(self?.mapController)
                        }
                    }
                } else {
                    self?.storeRestrsInRealm(false, nil, lineString)
                    self?.mapController.cancelLine(self?.mapController)
                    // put the restrictions in the realm for later
                }
            }
        } else {
            // put it in the db to try to upload later
            self.storeRestrsInRealm(false, nil, lineString)
            self.mapController.cancelLine(self.mapController)
        }
        //mapController.findClosestLine(begin, end)
        return false
        
    }
    func storeRestrsInRealm(_ sentSuccessfully: Bool, _ id: String?, _ lineString: String) {
        let line = Lines()
        line.line = lineString
        line.date = Date()
        for r in restrictions {
            let x = RestrictionType()
            x.type = r.type
            x.angle = r.angle
            x.cost = r.cost
            x.per = r.per
            for val in r.days {
                x.days.append(val)
            }
            for val in r.weeks {
                x.weeks.append(val)
            }
            for val in r.months {
                x.months.append(val)
            }
            x.duration = r.timeLimit
            x.start = r.fromTime
            x.end = r.toTime
            x.holiday = r.enforcedHolidays
            x.permit = r.permit
            x.side = r.side
            line.restrictions.append(x)
        }
        line.id = id
        line.uploaded = sentSuccessfully
        try! realm.write {
            realm.add(line)
        }
        self.restrictions = []
    }

    func uploadIfOnWifi() {
        if (NetworkReachabilityManager()?.isReachableOnEthernetOrWiFi)! {
            let filteredLines = realm.objects(Lines.self).filter("uploaded == false")
            print(filteredLines)
            if (filteredLines.count > 0) {
                for line in filteredLines {
                    let lineFloats = line.line!.split(separator: ",").map{Double($0)!}
                    var lineStruct : [[Double]] = []
                    for i in stride(from: 0, to: lineFloats.count, by: 2) {
                        lineStruct.append([lineFloats[i], lineFloats[i+1]])
                    }
                    var restrictionArray: [[String: Any]] = []
                    for r in line.restrictions {
                        let R = Restriction(type: r.type, days: Array(r.days), weeks: Array(r.weeks), months: Array(r.months), from: r.start, to: r.end, angle: r.angle, holidays: r.holiday, vehicle: r.vehicle, side: r.side, limit: r.duration, cost: r.cost, per: r.per, permit: r.permit)
                        restrictionArray.append(R.asDictionary())
                    }
                    let parameters: Parameters = [
                        "line": lineStruct,
                        "restrictions": restrictionArray
                        ]
                    print(parameters)
                    let headers: HTTPHeaders = [
                        "Content-Type": "application/json",
                        "session": self.user.get_session(),
                    ]
                    Alamofire.request("https://curbmap.com:50003/addLine", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { [weak self] response in
                        guard self != nil else { return }
                        if var json = response.result.value as? [String: Any] {
                            print("xxxzzz")
                            print(json)
                            if let success = json["success"] as? Int {
                                if (success == 1) {
                                    // put restrictions in realm as complete
                                    try! self?.realm.write {
                                        line.uploaded = true
                                        line.id = json["line_id"] as? String
                                    }
                                } else {
                                    // do nothing, try later ???
                                }
                            }
                        } else {
                            // do nothing, try later ???
                        }
                    }

                }
            }
            let filteredImages = realm.objects(Images.self).filter("uploaded == false")
            if (filteredImages.count > 0) {
                // get the image and upload it!
                for image in filteredImages {
                    if let olc = try? OpenLocationCode.encode(latitude: image.latitude, longitude: image.longitude, codeLength: 12) {
                        PHPhotoLibrary.shared().load(identifier: image.localIdentifier, appDelegate: self, olc: olc, heading: image.heading)
                    }
                }
            }
        }
    }
    @objc func uploadPhoto(data: Data, identifier: String, olc: String, heading: Double) {
        // do something
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
            "username": self.user.get_username(),
            "session": self.user.get_session()
        ]
        Alamofire.upload(multipartFormData: { MultipartFormData in
            MultipartFormData.append(olc.data(using: String.Encoding.utf8)!, withName: "olc")
            MultipartFormData.append("\(heading)".data(using: String.Encoding.utf8)!, withName: "bearing")
            MultipartFormData.append(data, withName: "image", fileName: "\(Date().iso8601).jpg", mimeType: "image/jpeg")
        }, usingThreshold:UInt64.init(), to: "https://curbmap.com:50003/imageUpload", method: .post, headers: headers, encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    if let result = response.result.value {
                        print(response)
                        if let success = result as? NSDictionary {
                            print("\(success["success"]! as! Bool) XXX")
                            if ((success["success"]! as! Bool) == true) {
                                
                                guard let foundImage = self.realm.objects(Images.self).filter("localIdentifier == \"\(identifier)\"").first else {
                                    return
                                }
                                try! self.realm.write {
                                    foundImage.uploaded = true
                                }
                            }
                            return
                        }
                        
                    }
                }
                break
            case .failure(let encodingError):
                print("failed to send \(encodingError.localizedDescription)")
            }
        })

        print("here in upload photo for \(identifier) with olc \(olc)")
        
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
            } else {
                NetworkManager.shared.startNetworkReachabilityObserver()
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
    
    @objc func save_image_data(localIdentifier: String, heading: Double, lat:  Double, lng: Double, uploaded: Bool) {
        DispatchQueue.main.async {
            let newImage = Images()
            newImage.localIdentifier = localIdentifier
            newImage.heading = heading
            newImage.latitude = lat
            newImage.longitude = lng
            newImage.uploaded = uploaded
            try! self.realm.write {
                self.realm.add(newImage)
            }
        }
    }
    
    @objc func find_image_data(_ localIdentifier: String) -> [String: Any]? {
        let file_searched = realm.objects(Images.self).filter("localIdentifer == \(localIdentifier)").first
        if let file_found = file_searched {
            return [
                "heading": file_found.heading,
                "latitude": file_found.latitude,
                "longitude": file_found.longitude,
                "uploaded": file_found.uploaded
            ]
        } else {
            return nil
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
            NetworkManager.shared.startNetworkReachabilityObserver()
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
    func getLineContributions() -> [LineContributions]? {
        let headers : HTTPHeaders = [
            "Content-Type": "application/x-www-form-urlencoded",
            "username": self.user.get_username(),
            "session": self.user.get_session()
        ]
        Alamofire.request("https://curbmap.com/getMyLines", method: .get, headers: headers).responseJSON { [weak self] response in
            guard self != nil else { return }
            if var json = response.result.value as? [String: Any] {
                if json.keys.contains("success") {
                    if let success = json["success"] as? Int {
                        if (success == 1) {
                        }
                    }
                }
            }
        }
        return nil
    }
    func getPhotoContributions() -> [PhotoContributions]? {
        return nil
    }
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
class Lines : Object {
    @objc dynamic var line: String!
    var restrictions = List<RestrictionType>()
    @objc dynamic var id: String!
    @objc dynamic var date: Date!
    @objc dynamic var uploaded: Bool = false
}

class RestrictionType : Object {
    var days = List<Bool>()
    var weeks = List<Bool>()
    var months = List<Bool>()
    @objc dynamic var type = 0
    @objc dynamic var vehicle = 0
    @objc dynamic var start = 0
    @objc dynamic var end = 0
    @objc dynamic var angle = 0
    @objc dynamic var side = 0
    var duration: Int?
    var permit: String?
    var cost: Float?
    var per: Int?
    @objc dynamic var holiday: Bool = true
}

class Images: Object {
    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var heading: Double = 0.0
    @objc dynamic var longitude: Double = 0.0
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var uploaded: Bool = false
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
