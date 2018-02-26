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
import Mixpanel

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
    var linesToDraw: [CurbmapPolyLine] = []
    var photosToDraw: [MapMarker] = []
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        center.delegate = notificationDelegate
        registerForPushNotifications()
        registerForLocalNotifications()
        center.getPendingNotificationRequests(completionHandler: notificationDelegate.gotPendingNotification)
        self.getSettings()
        self.getUser()
        Mixpanel.initialize(token: "80e860803728a01261a426e576895b30")
        Mixpanel.mainInstance().loggingEnabled = true
        Mixpanel.mainInstance().flushInterval = 5
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
        var lineCoords: [CLLocationCoordinate2D] = []
        var lineString = ""
        var newLine:CurbmapPolyLine!
        for i in 0..<self.mapController.line.count {
            line.append([self.mapController.line[i].coordinate.longitude, self.mapController.line[i].coordinate.latitude])
            lineCoords.append(self.mapController.line[i].coordinate)
            lineString += String(self.mapController.line[i].coordinate.longitude) + "," + String(self.mapController.line[i].coordinate.latitude) + ","
        }
        newLine = CurbmapPolyLine(coordinates: lineCoords, count: UInt(lineCoords.count))
        let lineStringEnd = lineString.index(lineString.startIndex, offsetBy: lineString.count-1)
        lineString = String(lineString[lineString.startIndex..<lineStringEnd]) // not including last ,
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "session": self.user.get_session(),
            "username": self.user.get_username()
        ]
        
        var restrParams: [[String: Any]] = []
        newLine.restrictions = restrictions
        var typeCount = [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        var permits: [String] = []
        for r in newLine.restrictions {
            if (r.isActiveNow()) {
                typeCount[r.type] += 1
            }
            if (r.permit != nil) {
                permits.append(r.permit!)
            }
        }
        if (typeCount[6] > 0 || typeCount[8] > 0 || (typeCount[7] > 0 && !permits.contains(self.user.searchSettings["permit"] as! String))) {
            newLine.color = UIColor.red
        } else if (typeCount[10] > 0) {
            newLine.color = UIColor.blue
        } else if (typeCount[0] > 0 || typeCount[1] > 0) {
            newLine.color = UIColor.green
        } else if (typeCount[2] > 0 || (typeCount[4] > 0 && !permits.contains(self.user.searchSettings["permit"] as! String))) {
            newLine.color = UIColor.gray
        } else if (typeCount[3] > 0 || (typeCount[5] > 0 && !permits.contains(self.user.searchSettings["permit"] as! String))) {
            newLine.color = UIColor.purple
        } else if (typeCount[9] > 0) {
            newLine.color = UIColor.brown
        } else if (typeCount[11] > 0) {
            newLine.color = UIColor.white
        } else if (typeCount[12] > 0) {
            newLine.color = UIColor.yellow
        } else if (typeCount.max()! > 0){
            newLine.color = UIColor.black
        } else {
            newLine.color = UIColor.clear
        }
        linesToDraw.append(newLine)
        if (mapController != nil) {
            mapController.triggerDrawLines()
        }
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
                            self?.mapController.doneWithLine(self?.mapController)
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
    func saveSearchSettings(limit: String, distance: String, date: DateComponents){
        guard let settings = realm.objects(SearchSettings.self).first else {
            let newSettings = SearchSettings()
            newSettings.day = date.weekday!
            newSettings.hour = date.hour!
            newSettings.minute = date.minute!
            newSettings.distance = Float(distance)!
            newSettings.limit = Int(limit)!
            try! realm.write {
                realm.add(newSettings)
            }
            return
        }
        try! realm.write {
            settings.day = date.weekday!
            settings.hour = date.hour!
            settings.minute = date.minute!
            settings.distance = Float(distance)!
            settings.limit = Int(limit)!
        }
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
            print("YYYZZZyyy")
            print(x.days)
            print(r.days)
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
    func getLinesAndPhotos() {
        self.linesToDraw = []
        let lines = realm.objects(Lines.self)
        var linesToSend: [Lines] = []
        for line in lines {
            if (!line.uploaded) {
                linesToSend.append(line)
            }
            var tempRestr: [Restriction] = []
            var lineStruct : [CLLocationCoordinate2D] = []
            var tempPoly: CurbmapPolyLine!
            let lineFloats = line.line!.split(separator: ",").map{Double($0)!}
            for i in stride(from: 0, to: lineFloats.count, by: 2) {
                let M = CLLocationCoordinate2D(latitude: lineFloats[i+1], longitude: lineFloats[i])
                lineStruct.append(M)
            }
            tempPoly = CurbmapPolyLine(coordinates: lineStruct, count: UInt(lineStruct.count))
            var typeCount = [0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            var permits: [String] = []
            for r in line.restrictions {
                print("XXX")
                print(Array(r.days))
                let R = Restriction(type: r.type, days: Array(r.days), weeks: Array(r.weeks), months: Array(r.months), from: r.start, to: r.end, angle: r.angle, holidays: r.holiday, vehicle: r.vehicle, side: r.side, limit: r.duration, cost: r.cost, per: r.per, permit: r.permit)
                if (R.isActiveNow()) {
                    print(lineFloats)
                    print(r.type)
                    typeCount[r.type] += 1
                }
                if (R.permit != nil) {
                    permits.append(R.permit!)
                }
                tempRestr.append(R)
            }
            // only the first point of a line gets
            tempPoly.restrictions = tempRestr
            let max = typeCount.max()
            print(max!, ": max")
            print(typeCount, ": max typecount")
            if (typeCount[6] > 0 || typeCount[8] > 0 || (typeCount[7] > 0 && !permits.contains(self.user.searchSettings["permit"] as! String))) {
                tempPoly.color = UIColor.red
            } else if (typeCount[10] > 0) {
                tempPoly.color = UIColor.blue
            } else if (typeCount[0] > 0 || typeCount[1] > 0) {
                tempPoly.color = UIColor.green
            } else if (typeCount[2] > 0 || (typeCount[4] > 0 && !permits.contains(self.user.searchSettings["permit"] as! String))) {
                tempPoly.color = UIColor.gray
            } else if (typeCount[3] > 0 || (typeCount[5] > 0 && !permits.contains(self.user.searchSettings["permit"] as! String))) {
                tempPoly.color = UIColor.purple
            } else if (typeCount[9] > 0) {
                tempPoly.color = UIColor.brown
            } else if (typeCount[11] > 0) {
                tempPoly.color = UIColor.white
            } else if (typeCount[12] > 0) {
                tempPoly.color = UIColor.yellow
            } else if (typeCount.max()! > 0){
                tempPoly.color = UIColor.black
            } else {
                tempPoly.color = UIColor.clear
            }
            self.linesToDraw.append(tempPoly)
        }
        let photos = realm.objects(Images.self)
        var photosToSend: [Images] = []
        for photo in photos {
            if (!photo.uploaded) {
                photosToSend.append(photo)
            }
            do {
                let codeArea = try OpenLocationCode.decode(code: photo.olc)
            let M = MapMarker(coordinate: CLLocationCoordinate2D(latitude: codeArea.LatLng().latitude, longitude: codeArea.LatLng().longitude))
            M.heading = photo.heading
            M.type = MapMarker.AnnotationType.photoNotDraggable
            self.photosToDraw.append(M)
            } catch(let error) {
                print(error);
            }
        }
        if (mapController != nil) {
            mapController.triggerDrawLines()
        }
        uploadIfOnWifi(lines: linesToSend, photos: photosToSend)
    }
    func uploadIfOnWifi(lines: [Lines], photos: [Images]) {
        if ((NetworkReachabilityManager()?.isReachableOnEthernetOrWiFi)! || (self.user.settings["offline"] == "n")) {
            if (lines.count > 0) {
                for line in lines {
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
            if (photos.count > 0) {
                PhotoHandler.sharedInstance.upload(photos)
            }
        }
    }
    @objc func uploadPhoto(data: Data, identifier: String, olc: String, heading: Double) {
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
                self.getLinesAndPhotos()
            }
        } catch _ {
            print("cannot get username")
            NetworkManager.shared.startNetworkReachabilityObserver()
            self.getLinesAndPhotos()
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
        guard let searchSettings = realm.objects(SearchSettings.self).first else {
            return
        }
        self.user.searchSettings.updateValue(searchSettings.day, forKey: "weekday")
        self.user.searchSettings.updateValue(searchSettings.hour, forKey: "hour")
        self.user.searchSettings.updateValue(searchSettings.minute, forKey: "minute")
        self.user.searchSettings.updateValue(searchSettings.limit, forKey: "limit")
        self.user.searchSettings.updateValue(searchSettings.distance, forKey: "distance")
        
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
            let protectionSpace = URLProtectionSpace.init(host: "curbmap.com",
                                                          port: 50003,
                                                          protocol: "https",
                                                          realm: nil,
                                                          authenticationMethod: nil)
            
            let userCredential = URLCredential(user: user.get_username(),
                                               password: user.get_password(),
                                               persistence: .permanent)
            
            URLCredentialStorage.shared.setDefaultCredential(userCredential, for: protectionSpace)
            
            NetworkManager.shared.startNetworkReachabilityObserver()
            self.getLinesAndPhotos()
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

class SearchSettings: Object {
    @objc dynamic var limit: Int = 0
    @objc dynamic var distance: Float = 0.0
    @objc dynamic var day: Int = 0
    @objc dynamic var hour: Int = 0
    @objc dynamic var minute: Int = 0
}
