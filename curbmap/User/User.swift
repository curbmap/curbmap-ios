//
//  User.swift
//  curbmap
//
//  Created by Eli Selkin on 7/14/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import Foundation
import Alamofire
import KeychainAccess
import MapKit

class User {
    let keychain = Keychain(service: "com.curbmap.keys")
    var username: String
    var password: String
    var loggedIn: Bool = false
    var remember: Bool = false
    var session: String
    var score: Int64
    var badge: String
    var currentLocation: CLLocationCoordinate2D?
    var settings: [String: String] = [
        "mapstyle": "d",
        "follow": "y",
        "push": "n",
        "units": "mi",
        "offline": "n"
    ]
    init(username: String, password: String) {
        self.username = username
        self.password = password
        self.loggedIn = false
        self.badge = "beginner"
        self.score = 0
        self.session = ""
    }
    func set_location(location: CLLocationCoordinate2D) {
        self.currentLocation = location
    }
    func get_location() -> CLLocationCoordinate2D? {
        return self.currentLocation
    }
    func set_badge(badge: String) {
        self.badge = badge
    }
    func get_badge() -> String{
        return self.badge
    }
    func set_score(score: Int64) {
        self.score = score
    }
    func get_score() -> Int64 {
        return self.score
    }
    func set_session(session: String) {
        self.session = session
    }
    func get_session() -> String {
        return self.session
    }
    func set_username(username: String) {
        self.username = username
    }
    func get_username() -> String {
        return self.username
    }
    func set_password(password: String) -> Void {
        self.password = password
    }
    func set_remember(remember: Bool) -> Void {
        self.remember = remember
    }
    func get_password() -> String {
        return self.password
    }
    func login(callback: @escaping ()->Void) -> Void {
        let parameters = [
            "username": self.username,
            "password": self.password
        ]
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        var full_dictionary: [String: Any] = ["success": false]
        Alamofire.request("https://curbmap.com/login", method: .post, parameters: parameters, headers: headers).responseJSON { [weak self] response in
            guard self != nil else { return }
            print(response)
            if var json = response.result.value as? [String: Any] {
                json["success"] = true
                full_dictionary = json
                self?.runDict(full_dictionary: full_dictionary, callback: callback)
            }
        }
    }
    
    func logout(callback: @escaping ()->Void) -> Void {
        print("logging out")
        let headers = [
            "session": self.get_session()
        ]
        Alamofire.request("https://curbmap.com/logout", method: .post, parameters: [:], headers: headers).responseJSON { response in
            if var json = response.result.value as? [String: Bool] {
                print(json["success"])
                if (json["success"] == true) {
                    print("succes")
                    self.loggedIn = false
                    self.set_badge(badge: "")
                    self.set_username(username: "curbmaptest")
                    self.set_session(session: "x")
                    self.set_score(score: 0)
                    self.set_password(password: "")
                    self.set_remember(remember: false)
                    try? self.keychain.removeAll()
                    callback()
                }
            }
        }
    }
    func changePassword(old_pass: String, new_pass: String, callback: @escaping (Int)->Void) -> Void {
        print("changing password")
        let headers = [
            "session": self.get_session()
        ]
        let parameters = [
            "username": self.get_username(),
            "password": old_pass,
            "newpassword": new_pass
        ]
        Alamofire.request("https://curbmap.com/changepassword", method: .post, parameters: parameters, headers: headers).responseJSON { response in
            if let json = response.result.value as? [String: Int] {
                print(json)
                callback(json["success"]!)
            }
        }
    }
    
    func resetPassword(callback: @escaping ()->Void) -> Void {
        print("resetting password")
        let headers = [
            "session": self.get_session()
        ]
        Alamofire.request("https://curbmap.com/resetpassword", method: .post, headers: headers).response { response in
            print(response)
            callback()
        }
    }
    
    func runDict(full_dictionary: [String: Any], callback: ()->Void) {
        self.set_badge(badge: full_dictionary["badge"] as! String)
        self.set_score(score: (Int64)((full_dictionary["score"] as! NSString).intValue))
        self.set_session(session: full_dictionary["session"] as! String)
        self.loggedIn = true
        callback()
    }
    
    func isLoggedIn() -> Bool {
        return self.loggedIn;
    }
}
