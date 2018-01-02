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

class SignupViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var isPortrait: Bool!
    var originalOrientation: Bool!
    @IBOutlet weak var containerView: UIView! // for menu controller
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var menuButton: UIButton!
    var menuTableViewController: UITableViewController!
    //var menuTableView: UITableView!
    var menuOpen = false
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var usernameError: ErrorLabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordError: ErrorLabel!
    @IBOutlet weak var retypeLabel: UILabel!
    @IBOutlet weak var retype: UITextField!
    @IBOutlet weak var retypeError: ErrorLabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var emailError: ErrorLabel!
    @IBOutlet weak var signupButton: UIButton!
    var ratio = 660.0/620.0 // for logo dimension ratio
    var windowFrame: CGRect!
    var contentInsetOriginal: UIEdgeInsets!
    var viewSize: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.windowFrame = self.scrollView.frame
        //self.scrollView = UIScrollView(frame: self.scrollView.frame)
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.isScrollEnabled = true
        self.containerView.isHidden = true
        self.createCentralViews()
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            self.setupCentralViews(1)
        } else {
            self.setupCentralViews(2)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.scrollView.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    @objc func createCentralViews() {
        print("XXX IN CENTRAL VIEWS")
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
        self.usernameError.translatesAutoresizingMaskIntoConstraints = false
        self.usernameError.frame = CGRect(x: self.usernameError.frame.origin.x, y: self.usernameError.frame.origin.y, width: self.usernameError.frame.width, height: 0)
        self.passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        self.password.translatesAutoresizingMaskIntoConstraints = false
        self.passwordError.translatesAutoresizingMaskIntoConstraints = false
        self.passwordError.frame = CGRect(x: self.passwordError.frame.origin.x, y: self.passwordError.frame.origin.y, width: self.passwordError.frame.width, height: 0)
        self.retypeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.retype.translatesAutoresizingMaskIntoConstraints = false
        self.retypeError.translatesAutoresizingMaskIntoConstraints = false
        self.retypeError.frame = CGRect(x: self.retypeError.frame.origin.x, y:         self.retypeError.frame.origin.y, width: self.retypeError.frame.width, height: 0)
        self.emailLabel.translatesAutoresizingMaskIntoConstraints = false
        self.email.translatesAutoresizingMaskIntoConstraints = false
        self.emailError.translatesAutoresizingMaskIntoConstraints = false
        self.emailError.frame = CGRect(x: self.emailError.frame.origin.x, y:         self.emailError.frame.origin.y, width: self.emailError.frame.width, height: 0)
        self.signupButton.translatesAutoresizingMaskIntoConstraints = false
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
        self.retype.attributedPlaceholder = NSAttributedString(string: "retype", attributes: textAttributes)
        self.retype.tag = 2
        self.retype.returnKeyType = .next
        self.retype.delegate = self
        self.email.attributedPlaceholder = NSAttributedString(string: "email@emailcompany.com", attributes: textAttributes)
        self.email.tag = 3
        self.email.returnKeyType = .done
        self.email.delegate = self
        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
        self.scrollView.layoutSubviews()
        self.scrollView.layoutIfNeeded()
    }

    @objc func setupCentralViews(_ firstTime: Int) {
        self.viewSize = self.view.frame.size
        
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
        self.usernameError.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.username.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            if (self.usernameError.text! != "UsernameError") {
                make.height.equalTo(70).priority(1000.0)
            } else {
                make.height.equalTo(0).priority(1000.0)
            }
        })
        self.passwordLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.usernameError.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(21).priority(1000.0)
        }
        self.password.snp.remakeConstraints({(make) in
            make.top.equalTo(self.passwordLabel.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
        })
        self.passwordError.snp.remakeConstraints({(make) in
            make.top.equalTo(self.password.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            if (self.passwordError.text! != "PasswordError") {
                make.height.equalTo(70).priority(1000.0)
            } else {
                make.height.equalTo(0).priority(1000.0)
            }
        })
        self.retypeLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.passwordError.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(21).priority(1000.0)
        }
        self.retype.snp.remakeConstraints({(make) in
            make.top.equalTo(self.retypeLabel.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
        })
        self.retypeError.snp.remakeConstraints({(make) in
            make.top.equalTo(self.retype.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            if (self.retypeError.text! != "RetypeError") {
                make.height.equalTo(70).priority(1000.0)
            } else {
                make.height.equalTo(0).priority(1000.0)
            }
        })
        self.emailLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.retypeError.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(21).priority(1000.0)
        }
        self.email.snp.remakeConstraints({(make) in
            make.top.equalTo(self.emailLabel.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            make.height.equalTo(45).priority(1000.0)
        })
        self.emailError.snp.remakeConstraints({(make) in
            make.top.equalTo(self.email.snp.bottomMargin).offset(6).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).offset(-10).priority(1000.0)
            if (self.emailError.text! != "EmailError") {
                make.height.equalTo(70).priority(1000.0)
            } else {
                make.height.equalTo(0).priority(1000.0)
            }
        })
        self.signupButton.snp.remakeConstraints { (make) in
            make.top.equalTo(self.emailError.snp.bottomMargin).offset(10).priority(1000.0)
            make.centerX.equalTo(self.scrollView.snp.centerX).priority(1000.0)
            make.width.equalTo(100).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
        }
        //self.view.layoutSubviews()
        self.view.layoutIfNeeded()
        //self.scrollView.layoutSubviews()
        self.scrollView.layoutIfNeeded()
    }

    @objc func destroyViews() {
        
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
        self.scrollView.setContentOffset(CGPoint(x:contentInsetOriginal.left, y:0.0), animated: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func dismissKeyboard() {
        self.password.endEditing(true)
        self.username.endEditing(true)
        self.retype.endEditing(true)
        self.email.endEditing(true)
        self.containerView.isHidden = true
        menuOpen = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == 0) {
            self.password.becomeFirstResponder()
        } else if (textField.tag == 1){
            self.retype.becomeFirstResponder()
        } else if (textField.tag == 2) {
            self.email.becomeFirstResponder()
        } else {
            self.email.resignFirstResponder()
            self.scrollView.endEditing(true)
        }
        return false
    }
    
    
    // Hide table view tap on map or button
    @IBAction func menuButtonPressed(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
        //self.menuTableViewController.tableView.reloadData()
    }
    @IBAction func signup(_ sender: Any) {
        self.usernameError.text = "UsernameError"
        self.passwordError.isHidden = true
        self.passwordError.text = "PasswordError"
        self.passwordError.isHidden = true
        self.retypeError.text = "RetypeError"
        self.retypeError.isHidden = true
        self.emailError.text = "EmailError"
        self.emailError.isHidden = true
        self.setupCentralViews(0)
        if (abs(self.username.text!.count.distance(to: 0)) < 4) {
            alertUsernameAllows()
            return
        }
        let userNotAllowed = "[^a-zA-Z@._\\-']+"
        let patSpecial = "[~!@#$%^&*()\\-_+=,.<>?:;]+"
        let patNumber = "[0-9]+"
        let patCap = "[A-Z]+"
        let patLow = "[a-z]+"
        if (checkPassword(username.text!, userNotAllowed)) {
            alertUsernameAllows()
            return
        }
        // It's so frustrating that password.text!.count returns not an Int! Who does that?!
        if (!(abs(self.password.text!.count.distance(to: 0)) >= 9 && abs(self.password.text!.count.distance(to: 0)) <= 40)) {
            alertPasswordMustContain()
            return
        }
        
        if (!checkPassword(self.password.text!, patSpecial)) {
            alertPasswordMustContain()
            return
        }
        
        if (!checkPassword(self.password.text!, patNumber)) {
            alertPasswordMustContain()
            return
        }
        
        if (!checkPassword(self.password.text!, patCap)) {
            alertPasswordMustContain()
            return
        }
        if (!checkPassword(self.password.text!, patLow)) {
            alertPasswordMustContain()
            return
        }
        // Get a good password first, then make sure you copy it correctly!
        if (self.password.text != self.retype.text) {
            alertPasswordsMustBeEqual()
            return
        }
        if (!isValidEmail(testStr: self.email.text!)) {
            alertIncorrectEmail()
            return
        }
        
        appDelegate.user.set_username(username: username.text!)
        appDelegate.user.set_password(password: password.text!)
        appDelegate.user.set_email(email: email.text!)
        self.appDelegate.user.signup(callback: completeSignup)
    }
    @objc func empty() {
        self.usernameError.numberOfLines = 3
        self.usernameError.lineBreakMode = .byWordWrapping
        self.usernameError.text = "You must enter something for all fields to create an account."
        self.usernameError.isHidden = false
        self.setupCentralViews(1)
    }
    @objc func usernameTaken() {
        self.usernameError.numberOfLines = 3
        self.usernameError.lineBreakMode = .byWordWrapping
        self.usernameError.text = "Sorry, that username was already taken. Choose another."
        self.usernameError.isHidden = false
        self.setupCentralViews(1)
    }
    @objc func emailTaken() {
        self.emailError.text = "Sorry, that email is already being used. Use another or check your email for an account you might have created before."
        self.emailError.numberOfLines = 3
        self.emailError.lineBreakMode = .byWordWrapping
        self.emailError.isHidden = false
        self.setupCentralViews(1)
    }
    @objc func somethingHappened() {
        self.emailError.numberOfLines = 3
        self.emailError.lineBreakMode = .byWordWrapping
        self.emailError.text = "Something went wrong, and we weren't able to create the account. :-("
        self.emailError.isHidden = false
        self.setupCentralViews(1)
    }
    
    @objc func completeSignup(_ result: Int) -> Void {
        print(result)
        if (result == 1) {
            let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! LoginViewController
            appDelegate.windowLocation = 2
            let vcToRemove = (navigationController?.viewControllers.count)! - 1
            navigationController?.pushViewController(loginViewController, animated: true)
            var newSet = navigationController?.viewControllers
            newSet?.remove(at: vcToRemove)
            navigationController?.viewControllers = newSet!
        } else if (result == 0) {
            empty()
        } else if (result == -1) {
            usernameTaken()
        } else if (result == -2) {
            emailTaken()
        } else if (result == -3) {
            alertPasswordMustContain()
        } else if (result == -4) {
            alertIncorrectEmail()
        } else {
            somethingHappened()
        }
    }
    
    @objc func checkPassword(_ pass: String, _ exp: String) -> Bool {
        let regex =  try! NSRegularExpression(pattern: exp, options: [])
        let matches = regex.matches(in: pass, options: [], range: NSRange(location: 0, length: pass.count))
        return matches.count > 0
    }
    
    // MARK: - email validation
    // https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }

    
    @objc func alertUsernameAllows() {
        self.usernameError.numberOfLines = 3
        self.usernameError.lineBreakMode = .byWordWrapping
        self.usernameError.text = "Username must be > 3 characters and can only contain letters a-z A-Z and characters @, ., _, -, or ' "
        self.usernameError.isHidden = false
        self.setupCentralViews(1)
    }

    @objc func alertPasswordMustContain() {
        self.passwordError.numberOfLines = 3
        self.passwordError.lineBreakMode = .byWordWrapping
        self.passwordError.text = "Passwords must be 9 to 40 characters in length, contain at least one lowercase, one uppercase, one special character ~!@#$%^&*()-_+=,.<>?:;"
        self.passwordError.isHidden = false
        self.setupCentralViews(1)
    }
    
    @objc func alertPasswordsMustBeEqual() {
        self.retypeError.numberOfLines = 2
        self.retypeError.lineBreakMode = .byWordWrapping
        self.retypeError.text = "Passwords must be the same"
        self.retypeError.isHidden = false
        self.setupCentralViews(1)
    }
    
    @objc func alertIncorrectEmail() {
        self.emailError.numberOfLines = 2
        self.emailError.lineBreakMode = .byWordWrapping
        self.emailError.text = "Email must be format name@name.type like me@curbmap.com"
        self.emailError.isHidden = false
        self.setupCentralViews(1)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowMenuFromSignup") {
            let vc = segue.destination as! MenuTableViewController
            self.menuTableViewController = vc
        }
    }
}
// MARK: - Padding for textfields
// https://stackoverflow.com/questions/25367502/create-space-at-the-beginning-of-a-uitextfield
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}


