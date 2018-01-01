//
//  ViewControllerLogin.swift
//  curbmap
//
//  Created by Eli Selkin on 7/16/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import UIKit
import KeychainAccess
import SnapKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var isPortrait: Bool = true
    @IBAction func loginButton(_ sender: Any) {
        appDelegate.user.set_username(username: username.text!)
        appDelegate.user.set_password(password: password.text!)
        appDelegate.user.login(callback: self.completeLogin)
    }
    var menuTableViewController: UITableViewController!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBAction func menuButton(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
        self.menuTableViewController.tableView.reloadData()
    }
    @IBOutlet weak var remember: UISwitch!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var username: UITextField!
    let keychain = Keychain(service: "com.curbmap.keys")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.isExclusiveTouch = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.backgroundColor = UIColor.black

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        remember.isOn = false
        self.password.backgroundColor = UIColor(displayP3Red: 0.3, green: 0.3, blue: 0.3, alpha: 0.99)
        self.username.backgroundColor = UIColor(displayP3Red: 0.3, green: 0.3, blue: 0.3, alpha: 0.99)
        let fontColor = [ NSAttributedStringKey.foregroundColor: UIColor.white ]
        self.password.attributedPlaceholder = NSAttributedString(string: "password", attributes: fontColor)
        self.password.returnKeyType = .done
        self.password.tag = 1
        self.username.attributedPlaceholder = NSAttributedString(string: "username", attributes: fontColor)
        self.username.returnKeyType = .next
        self.username.tag = 0
        self.username.delegate = self
        self.password.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.scrollView.addGestureRecognizer(tap)
        if (self.isPortrait) {
            let ratio = 660.0/620.0
            self.view.insertSubview(self.logo, at: 0)
            self.logo.snp.remakeConstraints({(make) in
                make.centerX.equalTo(self.username.snp.centerX).priority(1000)
                make.bottom.equalTo(self.usernameLabel.snp.top).offset(-30).priority(1000)
                make.top.equalTo(self.view.snp.topMargin).offset(8).priority(1000)
                make.width.equalTo(self.logo.snp.height).multipliedBy(ratio).priority(1000)
                make.height.lessThanOrEqualTo(self.view.snp.height).multipliedBy(1.0/5.0).priority(1000.0)
            })
            self.username.snp.remakeConstraints({ (make) in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(50).priority(1000.0)
                make.top.equalTo(self.usernameLabel.snp.bottom).priority(1000.0)
            })
        }
        // Do any additional setup after loading the view.
    }
    @objc func dismissKeyboard() {
        self.password.endEditing(true)
        self.username.endEditing(true)
        self.containerView.isHidden = true
        menuOpen = false
    }
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (_) in
            let orient = UIApplication.shared.statusBarOrientation
            self.isPortrait = orient.isPortrait
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            if (self.isPortrait) {
                let ratio = 660.0/620.0
                self.view.insertSubview(self.logo, at: 0)
                self.logo.snp.remakeConstraints({(make) in
                    make.centerX.equalTo(self.username.snp.centerX).priority(1000)
                    make.bottom.equalTo(self.usernameLabel.snp.top).offset(-30).priority(1000)
                    make.top.equalTo(self.searchBar.snp.bottom).offset(8).priority(1000)
                    make.width.equalTo(self.logo.snp.height).multipliedBy(ratio).priority(1000)
                    make.height.lessThanOrEqualTo(self.view.snp.height).multipliedBy(1.0/5.0).priority(1000.0)
                })
                self.username.snp.remakeConstraints({ (make) in
                    make.leading.equalToSuperview()
                    make.trailing.equalToSuperview()
                    make.height.equalTo(50).priority(1000.0)
                    make.top.equalTo(self.usernameLabel.snp.bottom).priority(1000.0)
                })
            } else {
                self.logo.removeFromSuperview()
                print(self.logo)
                self.view.layoutIfNeeded()
            }
        })
    }

    @objc func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    @objc func completeLogin() -> Void {
        if (appDelegate.user.isLoggedIn()) {
            if (remember.isOn == true) {
                do {
                    try keychain.accessibility(.whenUnlockedThisDeviceOnly).set(username.text!, key: "user_curbmap")
                    try keychain.accessibility(.whenUnlockedThisDeviceOnly).set(password.text!, key: "pass_curbmap")
                } catch _ {
                    print("cannot get username")
                }
            }
            self.menuTableViewController.tableView.reloadData()
            self.navigationController?.popViewController(animated: true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == 0) {
            self.password.becomeFirstResponder()
        } else {
            self.password.resignFirstResponder()
            self.view.endEditing(true)
        }
        return false
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UITableViewController,
            segue.identifier == "ShowMenuFromLogin" {
            self.menuTableViewController = vc
        }
    }
    

    
}

