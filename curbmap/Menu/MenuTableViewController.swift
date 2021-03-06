//
//  MenuTableViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.separatorStyle = .none
        self.tableView.backgroundView?.backgroundColor = UIColor.clear
        self.tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        self.tableView.register(UINib(nibName: "GeneralMenuCell", bundle: nil), forCellReuseIdentifier: "GeneralMenuCell")
        
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (appDelegate.user.isLoggedIn() && appDelegate.user.username != "curbmaptest") {
            return 5
        } else {
            return 6
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (appDelegate.user.isLoggedIn() && appDelegate.user.username != "curbmaptest") {
            if (indexPath.row == appDelegate.windowLocation && indexPath.row == 0) {
                print("shouldn't be here")
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 1) {
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 2) {
                let vc = navigationController?.topViewController as! AlarmViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
            } else if (indexPath.row == 0 && appDelegate.windowLocation != 0) {
                // my places and other things!
                print("here in row 0")
                let userController = UserViewController(nibName: "UserViewController", bundle: nil)
                if (appDelegate.windowLocation != 1) {
                    navigationController?.popViewController(animated: true)
                }
                appDelegate.windowLocation = 0
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                navigationController?.pushViewController(userController, animated: true)
            }
            else if (indexPath.row == 1 && appDelegate.windowLocation != 1) {
                if (appDelegate.windowLocation != 1) {
                    navigationController?.popViewController(animated: true)
                }
                appDelegate.windowLocation = 1
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
            } else if (indexPath.row == 2 && appDelegate.windowLocation != 2) {
                let alarmViewController = AlarmViewController(nibName: "AlarmViewController", bundle: nil)
                if (appDelegate.windowLocation != 1) {
                    navigationController?.popViewController(animated: true)
                }
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                appDelegate.windowLocation = 2
                navigationController?.pushViewController(alarmViewController, animated: true)
            } else if (indexPath.row == 3 && appDelegate.windowLocation != 3) {
                // about
            } else if (indexPath.row == 4 && appDelegate.windowLocation != 4) {
                let settingsViewController = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
                if (appDelegate.windowLocation != 1) {
                    navigationController?.popViewController(animated: true)
                }
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                appDelegate.windowLocation = 4
                navigationController?.pushViewController(settingsViewController, animated: true)
            }
        }
        else {
            if (indexPath.row == appDelegate.windowLocation && indexPath.row == 0) {
                let vc = navigationController?.topViewController as! MapViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 1) {
                let vc = navigationController?.topViewController as! AlarmViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 2) {
                let vc = navigationController?.topViewController as! LoginViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 3) {
                let vc = navigationController?.topViewController as! SignupViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 4) {
                
            } else if(indexPath.row == appDelegate.windowLocation && indexPath.row == 5) {
                let vc = navigationController?.topViewController as! SettingsViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
            } else if (indexPath.row == 0 && appDelegate.windowLocation != 0) {
                if (appDelegate.windowLocation != 0) {
                    navigationController?.popViewController(animated: true)
                }
                let vc = navigationController?.topViewController as! MapViewController
                vc.containerView.isHidden = true
                vc.menuOpen = false
                appDelegate.windowLocation = 0
            } else if (indexPath.row == 1 && appDelegate.windowLocation != 1) {
                let alarmViewController = AlarmViewController(nibName: "AlarmViewController", bundle: nil)
                if (appDelegate.windowLocation != 0) {
                    navigationController?.popViewController(animated: true)
                }
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                appDelegate.windowLocation = 1
                navigationController?.pushViewController(alarmViewController, animated: true)
            } else if (indexPath.row == 2 && appDelegate.windowLocation != 2) {
                let loginViewController = LoginViewController(nibName: "LoginViewController", bundle: nil)
                if (appDelegate.windowLocation != 0) {
                    navigationController?.popViewController(animated: true)
                }
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                appDelegate.windowLocation = 2
                navigationController?.pushViewController(loginViewController, animated: true)
            } else if (indexPath.row == 3 && appDelegate.windowLocation != 3) {
                let signupViewController = SignupViewController(nibName: "SignupViewController", bundle: nil)
                if (appDelegate.windowLocation != 0) {
                    navigationController?.popViewController(animated: true)
                }
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                appDelegate.windowLocation = 3
                navigationController?.pushViewController(signupViewController, animated: true)
            } else if (indexPath.row == 4 && appDelegate.windowLocation != 4) {
                // about
            } else {
                let settingsViewController = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
                if (appDelegate.windowLocation != 0) {
                    navigationController?.popViewController(animated: true)
                }
                self.appDelegate.mapController.containerView.isHidden = true
                self.appDelegate.mapController.menuOpen = false
                appDelegate.windowLocation = 5
                navigationController?.pushViewController(settingsViewController, animated: true)
            }
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (appDelegate.user.isLoggedIn() && appDelegate.user.username != "curbmaptest") {
            if (indexPath.row == 0) {
                return 100;
            } else {
                return 62.0
            }
        } else {
            return 62.0
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (appDelegate.user.isLoggedIn() && appDelegate.user.username != "curbmaptest") {
            if (indexPath.row == 0) {
                let userCell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserCell
                userCell.username.text = appDelegate.user.username
                userCell.score.text = String(appDelegate.user.score)
                return userCell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralMenuCell") as! GeneralMenuCell
                if (indexPath.row == 1) {
                    cell.cellTitle.text = "Map"
                    cell.cellImage.image = UIImage(named: "map")
                    cell.cellDescription.text = "see the world!"
                } else if (indexPath.row == 2) {
                    cell.cellTitle.text = "Alarm"
                    cell.cellImage.image = UIImage(named: "alarm")
                    cell.cellDescription.text = "remember the time!"
                } else if (indexPath.row == 3) {
                    cell.cellTitle.text = "About"
                    cell.cellImage.image = UIImage(named: "about")
                    cell.cellDescription.text = "learn about curbmap!"
                }  else if (indexPath.row == 4) {
                    cell.cellTitle.text = "Settings"
                    cell.cellImage.image = UIImage(named: "settings")
                    cell.cellDescription.text = "change defaults!"
                }
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralMenuCell") as! GeneralMenuCell
            if (indexPath.row == 0) {
                cell.cellTitle.text = "Map"
                cell.cellImage.image = UIImage(named: "map")
                cell.cellDescription.text = "see the world!"
            } else if (indexPath.row == 1) {
                cell.cellTitle.text = "Alarm"
                cell.cellImage.image = UIImage(named: "alarm")
                cell.cellDescription.text = "remember the time!"
            } else if (indexPath.row == 2) {
                cell.cellTitle.text = "Login"
                cell.cellImage.image = UIImage(named: "login")
                cell.cellDescription.text = "have fun!"
            } else if (indexPath.row == 3) {
                cell.cellTitle.text = "Signup"
                cell.cellImage.image = UIImage(named: "signup")
                cell.cellDescription.text = "get points!"
            } else if (indexPath.row == 4) {
                cell.cellTitle.text = "About"
                cell.cellImage.image = UIImage(named: "about")
                cell.cellDescription.text = "learn about curbmap!"
            }  else if (indexPath.row == 5) {
                cell.cellTitle.text = "Settings"
                cell.cellImage.image = UIImage(named: "settings")
                cell.cellDescription.text = "change defaults!"
            }
            
            return cell
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

