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
import NVActivityIndicatorView

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var error: ErrorLabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    var loading: NVActivityIndicatorView!
    var isPortrait: Bool = true
    var contentInsetOriginal: UIEdgeInsets!

    @IBOutlet weak var rememberLabel: UILabel!
    @IBOutlet weak var rememberSwitch: UISwitch!
    @IBAction func loginButtonPressed(_ sender: Any) {
        if !((self.appDelegate.reachabilityManager?.isReachable)!){
            self.error.text = "Network not reachable"
            self.setupCentralViews(2)
            return
        }
        self.error.text = "ErrorLabel"
        self.setupCentralViews(2)
        appDelegate.user.set_username(username: username.text!)
        appDelegate.user.set_password(password: password.text!)
        // load
        let size = self.viewSize.width/4
        let frame = CGRect(x: self.view.center.x-size/2, y: self.view.center.y-size/2, width: size, height: size)
        self.loading = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballClipRotatePulse, color: UIColor.white, padding: 7)
        self.view.addSubview(self.loading)
        self.loading.startAnimating()
        appDelegate.user.login(callback: self.completeLogin)
    }
    @IBOutlet weak var loginButton: UIButton!
    var tableView: UITableView!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBAction func menuButtonPressed(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
        self.tableView.reloadData()
    }
    @IBOutlet weak var remember: UISwitch!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var username: UITextField!
    let keychain = Keychain(service: "com.curbmap.keys")
    var ratio = 660.0/620.0 // for logo dimension ratio
    var windowFrame: CGRect!
    var viewSize: CGSize!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.isExclusiveTouch = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.backgroundColor = UIColor.black
        self.containerView.backgroundColor = UIColor.clear
        let vc = MenuTableViewController(nibName: "MenuTableViewController", bundle: nil)
        vc.willMove(toParentViewController: self)
        self.containerView.addSubview(vc.tableView)
        self.tableView = vc.tableView
        vc.tableView.frame = self.containerView.frame
        vc.tableView.snp.remakeConstraints { (make) in
            make.width.equalTo(self.containerView.snp.width).priority(1000.0)
            make.height.equalTo(self.containerView.snp.height).priority(1000.0)
            make.leading.equalTo(self.containerView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.containerView.snp.trailing).priority(1000.0)
            make.top.equalTo(self.containerView.snp.top).priority(1000.0)
            make.bottom.equalTo(self.containerView.snp.bottom).priority(1000.0)
        }
        self.addChildViewController(vc)
        vc.didMove(toParentViewController: self)

        self.createCentralViews()
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            self.setupCentralViews(1)
        } else {
            self.setupCentralViews(2)
        }
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
        // Do any additional setup after loading the view.
    }
    @objc func createCentralViews() {
        self.windowFrame =  self.view.frame
        self.scrollView.isExclusiveTouch = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.frame = self.windowFrame
        self.scrollView.backgroundColor = UIColor.black
        self.scrollView.alwaysBounceHorizontal = false
        self.menuButton.translatesAutoresizingMaskIntoConstraints = false
        self.logo.translatesAutoresizingMaskIntoConstraints = false
        self.usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.username.translatesAutoresizingMaskIntoConstraints = false
        self.passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        self.password.translatesAutoresizingMaskIntoConstraints = false
        self.error.translatesAutoresizingMaskIntoConstraints = false
        self.error.frame = CGRect(x: self.error.frame.origin.x, y: self.error.frame.origin.y, width: self.error.frame.width, height: 0)
        self.loginButton.translatesAutoresizingMaskIntoConstraints = false
        let textAttributes: [NSAttributedStringKey:Any] = [
            NSAttributedStringKey.foregroundColor : UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.8)
        ]
        self.username.attributedPlaceholder = NSAttributedString(string: "username", attributes: textAttributes)
        self.username.tag = 0
        self.username.returnKeyType = .next
        self.username.delegate = self
        self.password.attributedPlaceholder = NSAttributedString(string: "password", attributes: textAttributes)
        self.password.tag = 1
        self.password.returnKeyType = .next
        self.password.delegate = self
        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
        self.scrollView.layoutSubviews()
        self.scrollView.layoutIfNeeded()
    }

    @objc func setupCentralViews(_ firstTime: Int) {
        viewSize = self.view.frame.size
        
        if ((firstTime != 1 && firstTime != 2) &&
            ((!UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width > viewSize.height) ||
                (UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width < viewSize.height))) {
            viewSize = CGSize(width: viewSize.height, height: viewSize.width)
        }
        
        self.menuButton.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.width.equalTo(64).priority(1000.0)
            make.height.equalTo(64).priority(1000.0)
        }
        // They should call it wasPortrait
        self.containerView.snp.remakeConstraints({(make) in
            make.leading.equalTo(self.menuButton.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.menuButton.snp.bottom).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin)
            if (viewSize.width < viewSize.height) {
                make.width.equalTo(viewSize.width/1.5).priority(1000.0)
            } else {
                make.width.equalTo(viewSize.width/2.0).priority(1000.0)
            }
        })
        self.logo.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX).priority(1000.0)
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.width.equalTo(self.logo.snp.height).multipliedBy(ratio).priority(1000.0)
            if (viewSize.width > viewSize.height) {
                make.height.equalTo(0).priority(1000.0)
            } else {
                make.height.equalTo(viewSize.height/5.0).priority(1000.0)
            }
        }
        self.scrollView.snp.remakeConstraints { (make) in
            if (viewSize.width > viewSize.height) {
                make.leading.equalTo(self.view.snp.leading).offset(5).priority(1000.0)
                make.trailing.equalTo(self.view.snp.trailing).inset(5).priority(1000.0)
                make.top.equalTo(self.menuButton.snp.bottom).priority(1000.0)
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
            } else {
                make.leading.equalTo(self.view.snp.leading).offset(5).priority(1000.0)
                make.trailing.equalTo(self.view.snp.trailing).inset(5).priority(1000.0)
                make.top.equalTo(self.logo.snp.bottom).priority(1000.0)
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
            }
        }
        self.usernameLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.scrollView.snp.topMargin).offset(40).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).inset(20).priority(1000.0)
            make.height.equalTo(21).priority(1000.0)
        }
        self.username.snp.remakeConstraints({(make) in
            make.top.equalTo(self.usernameLabel.snp.bottom).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
        })

        self.passwordLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.username.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(21).priority(1000.0)
        }
        self.password.snp.remakeConstraints({(make) in
            make.top.equalTo(self.passwordLabel.snp.bottom).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
        })
        self.error.snp.remakeConstraints({(make) in
            make.top.equalTo(self.password.snp.bottom).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).priority(1000.0)
            make.width.equalTo(viewSize.width-20).priority(1000.0)
            if (self.error.text! != "ErrorLabel") {
                make.height.equalTo(70).priority(1000.0)
            } else {
                make.height.equalTo(0).priority(1000.0)
            }
        })
        self.rememberSwitch.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.error.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
        })
        self.rememberLabel.snp.remakeConstraints({ (make) in
            make.centerY.equalTo(self.rememberSwitch.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.rememberSwitch.snp.trailing).offset(8).priority(1000.0)
        })
        self.loginButton.snp.remakeConstraints({ (make) in
            make.centerX.equalTo(self.scrollView.snp.centerX).priority(1000.0)
            make.top.equalTo(self.rememberSwitch.snp.bottom).priority(1000.0)
            make.width.equalTo(100.0).priority(1000.0)
            make.height.equalTo(50.0).priority(1000.0)
        })


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
            self.scrollView.contentSize = CGSize(width: 0.9*viewSize.width, height: 1000)
            self.scrollView.isScrollEnabled = true
        }
    }

    
    @objc func dismissKeyboard() {
        self.password.endEditing(true)
        self.username.endEditing(true)
        self.containerView.isHidden = true
        menuOpen = false
    }


    @objc func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        self.contentInsetOriginal = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 45 // There's the key sign thing that's not part of the keyboard that may also show, maybe
        self.scrollView.contentInset = contentInset
    }
    @objc func keyboardWillHide(notification:NSNotification){
        if (contentInsetOriginal != nil) {
            self.scrollView.setContentOffset(CGPoint(x:contentInsetOriginal.left, y:0.0), animated: true)
        }
    }
    
    @objc func completeLogin(_ result: Int) -> Void {
        self.loading.stopAnimating()
        self.loading.removeFromSuperview()
        
        if (appDelegate.user.isLoggedIn()) {
            if (remember.isOn == true) {
                do {
                    try keychain.accessibility(.whenUnlockedThisDeviceOnly).set(username.text!, key: "user_curbmap")
                    try keychain.accessibility(.whenUnlockedThisDeviceOnly).set(password.text!, key: "pass_curbmap")
                } catch _ {
                    print("cannot get username")
                }
            }
            self.tableView.reloadData()
            self.appDelegate.windowLocation = 0
            self.navigationController?.popViewController(animated: true)
        } else {
            // alert user about error
            if (result == 0) {
                self.error.text = "Incorrect password. Please try again."
            } else if (result == -1) {
                print("Not authenticated!")
                self.error.text = "Check your email. You were sent something from curbmap to authorize this account."
            } else if (result == -2) {
                self.error.text = "Check that you entered your username correctly. It didn't appear in our system. You can log in either with your username or email address."
            }
            self.setupCentralViews(2)
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
}


