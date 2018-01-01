//
//  SettingsViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import KeychainAccess


class SettingsViewController: UIViewController {
    var menuTableViewController: UITableViewController!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBAction func logoutPressed(_ sender: Any) {
        self.appDelegate.user.logout(callback: self.finishedLogout)
    }
    @objc func finishedLogout() {
        self.menuTableViewController.tableView.reloadData()
        print("Logged out")
    }
    @IBOutlet weak var mapstyleLabel: UILabel!
    @IBOutlet weak var mapsstyleOutlet: UISwitch!
    @IBAction func mapstyleSwitch(_ sender: Any) {
        if (self.mapsstyleOutlet.isOn) {
            self.mapstyleLabel.text = "Light is my friend"
            self.appDelegate.user.settings.updateValue("l", forKey: "mapstyle")
            try! appDelegate.keychain.set("l", key:"settings_mapstyle")
        } else {
            self.mapstyleLabel.text = "Dark is best"
            self.appDelegate.user.settings.updateValue("d", forKey: "mapstyle")
            try! appDelegate.keychain.set("d", key:"settings_mapstyle")
        }
        appDelegate.mapController.changeStyle(style: appDelegate.user.settings["mapstyle"]!)
    }
    
    
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet weak var unitsOutlet: UISwitch!
    @IBAction func unitsSwitch(_ sender: Any) {
        if (!self.unitsOutlet.isOn) {
            self.unitsLabel.text = "The rest of the world (Km)"
            self.appDelegate.user.settings.updateValue("km", forKey: "units")
            try! appDelegate.keychain.set("km", key:"settings_units")
        } else {
            self.unitsLabel.text = "Only the US (Mi)"
            self.appDelegate.user.settings.updateValue("mi", forKey: "units")
            try! appDelegate.keychain.set("mi", key:"settings_units")
        }
        appDelegate.mapController.changeUnits(units: appDelegate.user.settings["units"]!)
    }
    
    @IBOutlet weak var offlineLabel: UILabel!
    @IBOutlet weak var offlineOutlet: UISwitch!
    @IBAction func offlineSwitch(_ sender: Any) {
        if (self.offlineOutlet.isOn) {
            self.offlineLabel.text = "Save data, get maps on wifi"
            self.appDelegate.user.settings.updateValue("n", forKey: "offline")
            try! appDelegate.keychain.set("n", key:"settings_offline")
            let alert = UIAlertController(title: "Offline maps", message: "By turning this off, we cannot give you regular updates about the status of parking.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Agree", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.offlineLabel.text = "I need the latest updates"
            self.appDelegate.user.settings.updateValue("y", forKey: "offline")
            try! appDelegate.keychain.set("y", key:"settings_offline")
        }
        appDelegate.mapController.changeOffline(offline: appDelegate.user.settings["offline"]!)
    }
    
    @IBOutlet weak var pushLabel: UILabel!
    @IBOutlet weak var pushOutlet: UISwitch!
    @IBAction func pushSwitch(_ sender: Any) {
        if (!self.pushOutlet.isOn) {
            self.pushLabel.text = "Don't send me notifications"
            self.appDelegate.user.settings.updateValue("n", forKey: "push")
            self.appDelegate.localNotificationsAllowed = false
            self.appDelegate.remoteNotificationsAllowed = false
            try! appDelegate.keychain.set("n", key:"settings_push")
        } else {
            self.pushLabel.text = "Send me notifications"
            self.appDelegate.user.settings.updateValue("y", forKey: "push")
            try! appDelegate.keychain.set("y", key:"settings_push")
            appDelegate.changePushStatus(status: appDelegate.user.settings["push"]!)
        }
    }
    @objc func checkStatus() {
        if (self.appDelegate.user.settings["push"] == "y" && self.appDelegate.registeredForLocal == false) {
            let alert = UIAlertController(title: "Push notifications", message: "We noticed you would like push notifications. For this you must open Settings > Notifcations > Curbmap > Allow Notifications.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Thanks", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            DispatchQueue.main.async {
                self.appDelegate.user.settings.updateValue("n", forKey: "push")
                try! self.appDelegate.keychain.set("n", key:"settings_push")
                self.pushLabel.text = "Change settings to enable push"
                self.pushOutlet.setOn(false, animated: true)
            }
        } else if (self.appDelegate.user.settings["push"] == "y") {
            self.pushOutlet.setOn(true, animated: true)
            // do nothing
        }
    }
    @IBOutlet weak var followLabel: UILabel!
    @IBOutlet weak var followOutlet: UISwitch!
    @IBAction func followSwitch(_ sender: Any) {
        if (!self.followOutlet.isOn) {
            self.followLabel.text = "Do not follow me"
            self.appDelegate.user.settings.updateValue("n", forKey: "follow")
            try! appDelegate.keychain.set("n", key:"settings_follow")
        } else {
            self.followLabel.text = "Move the map with me"
            self.appDelegate.user.settings.updateValue("y", forKey: "follow")
            try! appDelegate.keychain.set("y", key:"settings_follow")
        }
    }
    
    
    @IBOutlet weak var containerView: UIView!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBAction func menuButton(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
        self.menuTableViewController.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate.settingsController = self
        if (self.appDelegate.user.settings["mapstyle"] == "l") {
            self.mapsstyleOutlet.setOn(true, animated: false)
            self.mapstyleLabel.text = "Light is awesome"
        } else {
            self.mapsstyleOutlet.setOn(false, animated: false)
            self.mapstyleLabel.text = "Dark is best"
        }
        if(self.appDelegate.user.settings["units"] == "mi") {
            self.unitsOutlet.setOn(true, animated: false)
            self.unitsLabel.text = "Miles (US)"
        } else {
            self.unitsOutlet.setOn(false, animated: false)
            self.unitsLabel.text = "Meters (Everywhere else)"
        }
        if (self.appDelegate.user.settings["follow"] == "y") {
            self.followOutlet.setOn(true, animated: false)
            self.followLabel.text = "Follow my location on the map"
        } else {
            self.followOutlet.setOn(false, animated: false)
            self.followLabel.text = "Don't follow my location"
        }
        if (self.appDelegate.user.settings["push"] == "y") {
            self.pushOutlet.setOn(true, animated: false)
            self.pushLabel.text = "Send push notifications"
        } else {
            self.pushOutlet.setOn(false, animated: false)
            self.pushLabel.text = "Don't send notifications"
        }
        if (self.appDelegate.user.settings["offline"] == "n") {
            self.offlineOutlet.setOn(true, animated: false)
            self.offlineLabel.text = "I need the latest maps"
        } else {
            self.offlineOutlet.setOn(false, animated: false)
            self.offlineLabel.text = "I only want to use wifi"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.appDelegate.settingsController = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UITableViewController,
            segue.identifier == "ShowMenuFromSettings" {
            self.menuTableViewController = vc
        }
    }

}
