//
//  RestrictionViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 1/7/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import UIKit
import SnapKit


class RestrictionViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var doneButtonOutlet: UIButton!
    @IBAction func doneButtonAction(_ sender: Any) {
        self.addCurrentRestriction()
        self.appDelegate.submitRestrictions()
    }
    @IBOutlet weak var addAnotherOutlet: UIButton!
    @IBAction func addAnotherAction(_ sender: Any) {
        self.addCurrentRestriction()
        self.createCentralViews()
    }
    @IBOutlet weak var cancelOutlet: UIButton!
    @IBAction func cancelAction(_ sender: Any) {
        if (self.appDelegate.restrictionsToAdd.count <= 0) {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.getLastRestriction()
        }
    }
    func addCurrentRestriction() {
        let restriction = Restriction(type: <#String#>)
        restriction
    }
    
    func getLastRestriction() {
        
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var curbView: UIScrollView!
    var curbColorValue = 0
    @IBOutlet weak var grayCurbOutlet: UIButton!
    @IBAction func grayCurbAction(_ sender: Any) {
        self.grayCurbOutlet.layer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8).cgColor
        self.blueCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.whiteCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.yellowCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.greenCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.redCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.curbColorValue = 0
        self.meterOutlet.isHidden = false
        self.meterOutlet.setOn(false, animated: true)
        self.permitOutlet.selectedSegmentIndex = 2
        self.setupCentralViews()
    }
    @IBOutlet weak var curbColor: UILabel!
    
    @IBOutlet weak var redCurbOutlet: UIButton!
    @IBAction func redCurbAction(_ sender: Any) {
        self.grayCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.blueCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.whiteCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.yellowCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.greenCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.redCurbOutlet.layer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8).cgColor
        self.curbColorValue = 1
        self.meterOutlet.setOn(false, animated: true)
        self.permitOutlet.selectedSegmentIndex = 2
        self.setupCentralViews()
    }
    @IBOutlet weak var greenCurbOutlet: UIButton!
    @IBAction func greenCurbAction(_ sender: Any) {
        self.grayCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.blueCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.whiteCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.yellowCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.greenCurbOutlet.layer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8).cgColor
        self.redCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.curbColorValue = 2
        self.meterOutlet.setOn(false, animated: true)
        self.setupCentralViews()
    }
    @IBOutlet weak var blueCurbOutlet: UIButton!
    @IBAction func blueCurbAction(_ sender: Any) {
        self.grayCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.blueCurbOutlet.layer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8).cgColor
        self.whiteCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.yellowCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.greenCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.redCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.curbColorValue = 3
        self.meterOutlet.setOn(false, animated: true)
        self.permitOutlet.selectedSegmentIndex = 0
        self.setupCentralViews()
    }
    
    @IBOutlet weak var yellowCurbOutlet: UIButton!
    @IBAction func yellowCurbAction(_ sender: Any) {
        self.grayCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.blueCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.whiteCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.yellowCurbOutlet.layer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8).cgColor
        self.greenCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.redCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.curbColorValue = 4
        self.meterOutlet.setOn(false, animated: true)
        self.setupCentralViews()
    }
    @IBOutlet weak var whiteCurbOutlet: UIButton!
    @IBAction func whiteCurbAction(_ sender: Any) {
        self.grayCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.blueCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.whiteCurbOutlet.layer.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.8).cgColor
        self.yellowCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.greenCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.redCurbOutlet.layer.backgroundColor = UIColor.clear.cgColor
        self.curbColorValue = 5
        self.meterOutlet.setOn(false, animated: true)
        self.setupCentralViews()
    }
    @IBOutlet weak var npnsOutlet: UISegmentedControl!
    
    @IBAction func npnsAction(_ sender: Any) {
        self.setupCentralViews()
    }
    @IBOutlet weak var permitOutlet: UISegmentedControl!
    @IBAction func permitAction(_ sender: Any) {
        self.setupCentralViews()
    }
    @IBOutlet weak var permitField: UITextField!
    @IBOutlet weak var permitLabel: UILabel!
    
    @IBOutlet weak var meterOutlet: UISwitch!
    @IBAction func meterAction(_ sender: Any) {
        if !(meterOutlet.isOn) {
            self.costField.text = nil
            self.perField.text = nil
        } else {
            self.costField.text = "0.0"
            self.perField.text = "0"
        }
        self.setupCentralViews()
    }
    
    @IBOutlet weak var meterView: UIScrollView!
    @IBOutlet weak var meterLabel: UILabel!
    @IBOutlet weak var costField: UITextField!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var perField: UITextField!
    @IBOutlet weak var perLabel: UILabel!
    @IBAction func currency(_ sender: Any) {
        self.setupCentralViews()
    }
    @IBOutlet weak var currencyOutlet: UISegmentedControl!
    
    @IBOutlet weak var timeLimitField: UITextField!
    @IBOutlet weak var timeLimitLabel: UILabel!
    @IBOutlet weak var addHour: UIButton!
    @IBAction func addHourAction(_ sender: Any) {
        if let time = self.timeLimitField.text {
            if var timeValue = Int(time) {
                timeValue += 60
                self.timeLimitField.text = String(timeValue)
            }
        } else {
            self.timeLimitField.text = "60"
        }
    }
    @IBOutlet weak var addTwoHours: UIButton!
    @IBAction func addTwoHoursAction(_ sender: Any) {
        if let time = self.timeLimitField.text {
            if var timeValue = Int(time) {
                timeValue += 120
                self.timeLimitField.text = String(timeValue)
            }
        } else {
            self.timeLimitField.text = "120"
        }
    }
    
    @IBOutlet weak var resetHours: UIButton!
    @IBAction func resetHoursAction(_ sender: Any) {
        self.timeLimitField.text = "0"
    }
    @IBOutlet weak var angleHeading: UILabel!
    @IBAction func angleAction(_ sender: Any) {
    }
    @IBOutlet weak var angleOutlet: UISegmentedControl!
    var contentInsetOriginal:UIEdgeInsets!
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
     
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
     
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
     
    }
    func createCentralViews() {
        self.curbView.isScrollEnabled = true
        self.curbView.isUserInteractionEnabled = true
        self.curbView.isExclusiveTouch = false
        self.curbView.isPagingEnabled = true
        self.curbView.delegate = self
        self.scrollView.isExclusiveTouch = false
        self.scrollView.isScrollEnabled = true
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.delegate = self
        self.scrollView.isPagingEnabled = true
        self.meterView.isExclusiveTouch = false
        self.meterView.isScrollEnabled = true
        self.meterView.isUserInteractionEnabled = true
        self.meterView.delegate = self
        self.meterView.isPagingEnabled = true
        self.costField.keyboardType = .numbersAndPunctuation
        self.costField.autocapitalizationType = .none
        self.costField.autocorrectionType = .no
        self.costField.placeholder = "e.g. $1.25"
        self.perField.keyboardType = .numbersAndPunctuation
        self.perField.autocapitalizationType = .none
        self.perField.autocorrectionType = .no
        self.perField.placeholder = "e.g. 30"
        self.timeLimitField.keyboardType = .numbersAndPunctuation
        self.timeLimitField.autocapitalizationType = .none
        self.timeLimitField.autocorrectionType = .no
        self.timeLimitField.placeholder = "e.g. 120"
        self.permitOutlet.selectedSegmentIndex = 2
        self.npnsOutlet.selectedSegmentIndex = 0
        self.meterOutlet.setOn(false, animated: true)
        self.currencyOutlet.selectedSegmentIndex = 0
        self.angleOutlet.selectedSegmentIndex = 0
        self.permitField.returnKeyType = .done
        self.permitField.delegate = self
        self.permitField.text = ""
        self.permitField.tag = 0
        self.costField.returnKeyType = .next
        self.costField.delegate = self
        self.costField.tag = 1
        self.costField.text = "0"
        self.perField.returnKeyType = .done
        self.perField.tag = 2
        self.perField.delegate = self
        self.perField.text = "0"
        self.timeLimitField.returnKeyType = .done
        self.timeLimitField.tag = 3
        self.timeLimitField.delegate = self
        self.timeLimitField.text = "0"
    }
    func setupCentralViews() {
        self.doneButtonOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.leading.equalTo(self.view.snp.leading).priority(1000.0)
        }
        self.addAnotherOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.centerX.equalTo(self.view.snp.centerX).priority(1000.0)
        }
        self.cancelOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.trailing.equalTo(self.view.snp.trailing).priority(1000)
        }
        self.scrollView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.doneButtonOutlet.snp.bottom).offset(15).priority(1000.0)
            make.leading.equalTo(self.view.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.view.snp.trailing).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottom).priority(1000.0)
            make.width.equalTo(self.view.snp.width).priority(1000.0)
        }
        self.curbColor.snp.remakeConstraints { (make) in
            make.top.equalTo(self.scrollView.snp.top).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leadingMargin).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).priority(1000.0)
            make.height.equalTo(32).priority(1000.0)
            make.width.equalTo(self.view.snp.width).priority(1000.0)
        }
        self.curbView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.curbColor.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.scrollView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).priority(1000.0)
            make.height.equalTo(120).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
        }
        self.grayCurbOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.curbView.snp.top).offset(8).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.curbView.snp.trailing).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(self.curbView.snp.width).inset(15).priority(1000.0)
        }
        self.redCurbOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.grayCurbOutlet.snp.bottom).offset(8).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.curbView.snp.trailing).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(self.curbView.snp.width).inset(15).priority(1000.0)
        }
        self.greenCurbOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.redCurbOutlet.snp.bottom).offset(8).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.curbView.snp.trailing).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(self.curbView.snp.width).inset(15).priority(1000.0)
        }
        self.blueCurbOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.greenCurbOutlet.snp.bottom).offset(8).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.curbView.snp.trailing).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(self.curbView.snp.width).inset(15).priority(1000.0)
        }
        
        self.yellowCurbOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.blueCurbOutlet.snp.bottom).offset(8).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.curbView.snp.trailing).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(self.curbView.snp.width).inset(15).priority(1000.0)
        }

        self.whiteCurbOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.yellowCurbOutlet.snp.bottom).offset(8).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.curbView.snp.trailing).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(self.curbView.snp.width).inset(15).priority(1000.0)
        }
        self.npnsOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.curbView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.curbView.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            if (self.curbColorValue == 1 || self.curbColorValue == 3) {
                self.npnsOutlet.isHidden = false
                make.height.equalTo(45).priority(1000.0)
            } else {
                self.npnsOutlet.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.permitOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.npnsOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.npnsOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            if (self.curbColorValue == 1 || self.curbColorValue == 3) {
                self.permitOutlet.isHidden = false
                make.height.equalTo(45).priority(1000.0)
            } else {
                self.permitOutlet.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.permitField.snp.remakeConstraints { (make) in
            make.top.equalTo(self.permitOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.permitOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).dividedBy(2.0).priority(1000.0)
            if (permitOutlet.selectedSegmentIndex == 1) {
                self.permitField.isHidden = false
                make.height.equalTo(45).priority(1000.0)
            } else {
                self.permitField.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.permitLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.permitField.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.permitField.snp.trailing).offset(10).priority(1000.0)
            if (permitOutlet.selectedSegmentIndex == 1) {
                self.permitLabel.isHidden = false
                make.height.equalTo(45).priority(1000.0)
            } else {
                self.permitLabel.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.meterOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.permitField.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.permitField.snp.leading).priority(1000.0)
        }
        self.meterLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.meterOutlet.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.meterOutlet.snp.trailing).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailing).priority(1000.0)
        }
        self.meterView.snp.remakeConstraints { (make) in
            if (self.meterOutlet.isOn) {
                make.top.equalTo(self.meterOutlet.snp.bottom).offset(10).priority(1000.0)
                make.leading.equalTo(self.meterOutlet.snp.leading).priority(1000.0)
                make.trailing.equalTo(self.scrollView.snp.trailingMargin).priority(1000.0)
                make.height.equalTo(150).priority(1000.0)
            } else {
                make.height.equalTo(0).priority(1000.0)
                make.top.equalTo(self.meterOutlet.snp.bottom).offset(10).priority(1000.0)
                make.leading.equalTo(self.meterOutlet.snp.leading).priority(1000.0)
                make.trailing.equalTo(self.scrollView.snp.trailingMargin).priority(1000.0)
            }
        }
        self.costField.snp.remakeConstraints { (make) in
            make.top.equalTo(self.meterView.snp.topMargin).priority(1000.0)
            make.leading.equalTo(self.meterView.snp.leading).priority(1000.0)
            make.width.equalTo(self.meterView.snp.width).dividedBy(2.0).priority(1000.0)
            make.height.equalTo(40).priority(1000.0)
        }
        self.costLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.costField.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.costField.snp.trailing).offset(10).priority(1000)
            make.height.equalTo(self.costField.snp.height)
        }
        self.perField.snp.remakeConstraints { (make) in
            make.top.equalTo(self.costField.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.meterView.snp.leading).priority(1000.0)
            make.width.equalTo(self.meterView.snp.width).dividedBy(2.0).priority(1000.0)
            make.height.equalTo(40).priority(1000.0)
        }
        self.perLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.perField.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.perField.snp.trailing).offset(10).priority(1000)
            make.height.equalTo(self.perField.snp.height)
        }
        self.currencyOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.perField.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.perField.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.meterView.snp.trailing).priority(1000.0)
            make.width.equalTo(self.meterView).priority(1000)
        }
        self.timeLimitField.snp.remakeConstraints { (make) in
            make.top.equalTo(self.meterView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.meterOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).dividedBy(2).priority(1000.0)
            make.height.equalTo(45).priority(1000.0)
        }
        self.timeLimitLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.timeLimitField.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.timeLimitField.snp.trailing).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailing).priority(1000.0)
            make.height.equalTo(45).priority(1000.0)
        }
        self.addHour.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.timeLimitField.snp.leading).offset(15).priority(1000.0)
            make.top.equalTo(self.timeLimitField.snp.bottom).offset(10).priority(1000.0)
        }
        self.addTwoHours.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.addHour.snp.trailing).offset(15).priority(1000.0)
            make.top.equalTo(self.addHour.snp.top).priority(1000.0)
        }
        self.resetHours.snp.remakeConstraints { (make) in
            make.trailing.equalTo(self.scrollView.snp.trailingMargin).inset(10).priority(1000.0)
            make.top.equalTo(self.addTwoHours.snp.top).priority(1000.0)
        }
        self.angleHeading.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.scrollView.snp.leading).priority(1000.0)
            make.top.equalTo(self.addHour.snp.bottom).priority(1000.0)
            make.height.equalTo(40).priority(1000.0)
        }
        self.angleOutlet.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.angleHeading.snp.leading).priority(1000.0)
            make.top.equalTo(self.angleHeading.snp.bottom).offset(10).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            make.height.equalTo(45).priority(1000.0)
        }

        self.viewWillLayoutSubviews()
    }
    override func viewWillLayoutSubviews(){
        super.viewWillLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: 900)
        curbView.contentSize = CGSize(width: self.view.frame.width, height: 360)
        meterView.contentSize = CGSize(width: self.view.frame.width, height: 300)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            let orient = UIApplication.shared.statusBarOrientation
            self.setupCentralViews()
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createCentralViews()
        self.setupCentralViews()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.scrollView.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissKeyboard() {
        self.costField.endEditing(true)
        self.perField.endEditing(true)
        self.timeLimitField.endEditing(true)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == 0) {
           self.view.endEditing(true)
            self.dismissKeyboard()
        } else if (textField.tag == 1) {
            self.costField.resignFirstResponder()
            self.perField.becomeFirstResponder()
        } else if (textField.tag == 2) {
            self.perField.resignFirstResponder()
            self.view.endEditing(true)
            self.dismissKeyboard()
        } else if (textField.tag == 3) {
            self.timeLimitField.resignFirstResponder()
            self.view.endEditing(true)
            self.dismissKeyboard()
        }
        return false
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
