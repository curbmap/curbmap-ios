//
//  SettingsViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import KeychainAccess
import SnapKit

class SettingsViewController: UIViewController {
    var menuTableViewController: UITableViewController!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var logoutButtonOutlet: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var menuButtonOutlet: UIButton!
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
            self.appDelegate.setSetting(setting: "mapstyle", value: "l")
        } else {
            self.mapstyleLabel.text = "Dark is best"
            self.appDelegate.user.settings.updateValue("d", forKey: "mapstyle")
            self.appDelegate.setSetting(setting: "mapstyle", value: "d")
        }
        appDelegate.mapController.changeStyle(style: appDelegate.user.settings["mapstyle"]!)
    }
    
    
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet weak var unitsOutlet: UISwitch!
    @IBAction func unitsSwitch(_ sender: Any) {
        if (!self.unitsOutlet.isOn) {
            self.unitsLabel.text = "The rest of the world (Km)"
            self.appDelegate.user.settings.updateValue("km", forKey: "units")
            self.appDelegate.setSetting(setting: "units", value: "km")
        } else {
            self.unitsLabel.text = "Only the US (Mi)"
            self.appDelegate.user.settings.updateValue("mi", forKey: "units")
            self.appDelegate.setSetting(setting: "units", value: "mi")
        }
        appDelegate.mapController.changeUnits(units: appDelegate.user.settings["units"]!)
    }
    
    @IBOutlet weak var offlineLabel: UILabel!
    @IBOutlet weak var offlineOutlet: UISwitch!
    @IBAction func offlineSwitch(_ sender: Any) {
        if (self.offlineOutlet.isOn) {
            self.offlineLabel.text = "Save data, get maps on wifi"
            self.appDelegate.user.settings.updateValue("n", forKey: "offline")
            self.appDelegate.setSetting(setting: "offline", value: "n")
            let alert = UIAlertController(title: "Offline maps", message: "By turning this off, we cannot give you regular updates about the status of parking.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Agree", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.offlineLabel.text = "I need the latest updates"
            self.appDelegate.user.settings.updateValue("y", forKey: "offline")
            self.appDelegate.setSetting(setting: "offline", value: "y")
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
            self.appDelegate.setSetting(setting: "push", value: "n")
        } else {
            self.pushLabel.text = "Send me notifications"
            self.appDelegate.user.settings.updateValue("y", forKey: "push")
            self.appDelegate.setSetting(setting: "push", value: "y")
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
                self.appDelegate.setSetting(setting: "push", value: "n")
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
            self.appDelegate.setSetting(setting: "follow", value: "n")
        } else {
            self.followLabel.text = "Move the map with me"
            self.appDelegate.user.settings.updateValue("y", forKey: "follow")
            self.appDelegate.setSetting(setting: "follow", value: "y")
        }
    }
    var viewSize: CGSize!
    
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
            self.offlineOutlet.setOn(false, animated: false)
            self.offlineLabel.text = "I need the latest maps"
        } else {
            self.offlineOutlet.setOn(true, animated: false)
            self.offlineLabel.text = "I only want to use wifi"
        }
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            self.setupCentralViews(1)
        } else {
            self.setupCentralViews(2)
        }
    }

    @objc func setupCentralViews(_ firstTime: Int) {
        viewSize = self.view.frame.size
        
        if ((firstTime != 1 && firstTime != 2) &&
            ((!UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width > viewSize.height) ||
                (UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width < viewSize.height))) {
            viewSize = CGSize(width: viewSize.height, height: viewSize.width)
        }
        
        self.menuButtonOutlet.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.width.equalTo(64).priority(1000.0)
            make.height.equalTo(64).priority(1000.0)
        }
        // They should call it wasPortrait
        self.containerView.snp.remakeConstraints({(make) in
            make.leading.equalTo(self.menuButtonOutlet.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.menuButtonOutlet.snp.bottom).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin)
            if (viewSize.width < viewSize.height) {
                make.width.equalTo(viewSize.width/1.5).priority(1000.0)
            } else {
                make.width.equalTo(viewSize.width/2.0).priority(1000.0)
            }
        })
        self.scrollView.snp.remakeConstraints { (make) in
            if (viewSize.width > viewSize.height) {
                make.leading.equalTo(self.view.snp.leading).offset(5).priority(1000.0)
                make.trailing.equalTo(self.view.snp.trailing).inset(5).priority(1000.0)
                make.top.equalTo(self.menuButtonOutlet.snp.bottom).priority(1000.0)
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
            } else {
                make.leading.equalTo(self.view.snp.leading).offset(5).priority(1000.0)
                make.trailing.equalTo(self.view.snp.trailing).inset(5).priority(1000.0)
                make.top.equalTo(self.menuButtonOutlet.snp.bottom).priority(1000.0)
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
            }
        }
        self.mapstyleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.scrollView.snp.topMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*3/4).priority(1000.0)
        }
        self.mapsstyleOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.scrollView.snp.topMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.mapstyleLabel.snp.trailing).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*1/4).priority(1000.0)
        }
        self.unitsLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.mapsstyleOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*3/4).priority(1000.0)
        }
        self.unitsOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.mapsstyleOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.unitsLabel.snp.trailing).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*1/4).priority(1000.0)
        }
        self.pushLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.unitsOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*3/4).priority(1000.0)
        }
        self.pushOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.unitsOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.pushLabel.snp.trailing).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*1/4).priority(1000.0)
        }
        self.followLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.pushOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*3/4).priority(1000.0)
        }
        self.followOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.pushOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.pushLabel.snp.trailing).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*1/4).priority(1000.0)
        }
        self.offlineLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.followOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*3/4).priority(1000.0)
        }
        self.offlineOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.followOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.offlineLabel.snp.trailing).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(viewSize.width*1/4).priority(1000.0)
        }
        self.logoutButtonOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.offlineOutlet.snp.bottomMargin).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.width.equalTo(150.0)
            make.height.equalTo(100.0)
        }
        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
        self.scrollView.layoutSubviews()
        self.scrollView.layoutIfNeeded()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.setupCentralViews(0)
    }
    
    override func viewWillLayoutSubviews(){
        super.viewWillLayoutSubviews()
        if (viewSize != nil) {
            self.scrollView.contentSize = CGSize(width: 0.9*viewSize.width, height: 750)
            self.scrollView.isScrollEnabled = true
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
