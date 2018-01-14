//
//  RestrictionViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 1/7/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

// TODO: Set up error checking to see if the rule the user is adding makes sense. If not, show an alert!

import UIKit
import SnapKit
import NVActivityIndicatorView

enum RestrictionError: Error {
    case incongruentTimeWithRestriction
    case incongruentCurbTypeWithMeter
    case costNotSpecifiedForMeter
    case perNotSpecifiedForMeter
    case timeLimitNotSpecified
    case incongruentPerTypeForMeter
}

class RestrictionViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var alertFG: UIView!
    var alertBG: UIView!
    func setCancel(function: @escaping(Any)->Void) {
        self.cancelLine = function
    }
    var loading: NVActivityIndicatorView!
    var cancelLine: ((Any) -> Void)?
    var startTimeDelegate: TimeDelegateData!
    var endTimeDelegate: TimeDelegateData!
    
    @IBOutlet weak var doneButtonOutlet: UIButton!
    @IBAction func doneButtonAction(_ sender: Any) {
        do {
            let added = try self.addCurrentRestriction()
            if (added == true) {
                self.appDelegate.submitRestrictions()
                self.navigationController?.popViewController(animated: true)
            } else {
                // put up error
                // No suitable type was found!
                errorAlert("No suitable type for this restriction was found. Let us know what happened by email at curbmap@curbmap.com. We'd love to hear about it!")
            }
        } catch let error as RestrictionError {
            if (error == RestrictionError.costNotSpecifiedForMeter) {
                errorAlert("Metered costs should be some decimal value like 0.25 or 1. You're making an excellent impact!")
            } else if (error == RestrictionError.incongruentCurbTypeWithMeter) {
                errorAlert("The type was incongruent with a meter. Like, red and a meter. Keep going!")
            } else if (error == RestrictionError.incongruentPerTypeForMeter) {
                errorAlert("Per values should be increments like 15 minutes or 20 minutes. We're not big fans of meters either.")
            } else if (error == RestrictionError.incongruentTimeWithRestriction) {
                errorAlert("For green restrictions, time limit should be under 60 minutes. For gray 60+. Thanks.")
            } else if (error == RestrictionError.perNotSpecifiedForMeter) {
                errorAlert("Per values help people expect how much parking will cost them. Thanks for adding one.")
            } else if (error == RestrictionError.timeLimitNotSpecified) {
                errorAlert("It'd be a wonderful world if there were no time limits on parking. Please add one for this type of restriction.")
            }
        } catch {
            //catchall
        }
    }
    @IBOutlet weak var addAnotherOutlet: UIButton!
    @IBAction func addAnotherAction(_ sender: Any) {
        let size = self.view.frame.width/4
        let frame = CGRect(x: self.view.center.x-size/2, y: self.view.center.y-size/2, width: size, height: size)
        self.loading = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballClipRotatePulse, color: UIColor.white, padding: 7)
        self.view.addSubview(loading)
        loading.startAnimating()
        do {
            let added = try self.addCurrentRestriction()
            if (added == true) {
                self.createCentralViews()
                self.setupCentralViews()
                self.loading.removeFromSuperview()
                self.loading.stopAnimating()
                self.loading = nil
            } else {
                // put up error
                // No suitable type was found!
                errorAlert("No suitable type for this restriction was found. Let us know what happened by email at curbmap@curbmap.com. We'd love to hear about it!")
            }
        } catch let error as RestrictionError {
            // put up error
            if (error == RestrictionError.costNotSpecifiedForMeter) {
                errorAlert("Metered costs should be some decimal value like 0.25 or 1. You're making an excellent impact!")
            } else if (error == RestrictionError.incongruentCurbTypeWithMeter) {
                errorAlert("The type was incongruent with a meter. Like, red and a meter. Keep going!")
            } else if (error == RestrictionError.incongruentPerTypeForMeter) {
                errorAlert("Per values should be increments like 15 minutes or 20 minutes. We're not big fans of meters either.")
            } else if (error == RestrictionError.incongruentTimeWithRestriction) {
                errorAlert("For green restrictions, time limit should be under 60 minutes. For gray 60+. Thanks.")
            } else if (error == RestrictionError.perNotSpecifiedForMeter) {
                errorAlert("Per values help people expect how much parking will cost them. Thanks for adding one.")
            } else if (error == RestrictionError.timeLimitNotSpecified) {
                errorAlert("It'd be a wonderful world if there were no time limits on parking. Please add one for this type of restriction.")
            }
        } catch {
            //catchall
        }
    }
    @objc func okPressed(_sender: Any) {
        self.alertFG.removeFromSuperview()
        self.alertBG.removeFromSuperview()
        self.alertFG = nil
        self.alertBG = nil
    }

    func generateAlert(_ message: String) -> UIView {
        let alertView = UIView()
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        let ok = UIButton(type: .system)
        ok.setTitle("Ok!", for: .normal)
        ok.addTarget(self, action: #selector(okPressed), for: .touchUpInside)
        alertView.addSubview(label)
        alertView.addSubview(ok)
        label.snp.remakeConstraints { (make) in
            make.top.equalTo(alertView.snp.topMargin).offset(10).priority(1000.0)
            make.leading.equalTo(alertView.snp.leadingMargin).offset(10).priority(1000.0)
            make.trailing.equalTo(alertView.snp.trailingMargin).inset(10).priority(1000.0)
            make.height.equalTo(alertView.snp.height).dividedBy(1.6)
        }
        label.textAlignment = .center
        
        ok.snp.remakeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(10).priority(1000.0)
            make.centerX.equalTo(alertView.snp.centerX).priority(1000.0)
        }
        alertView.backgroundColor = UIColor(red: 0.8, green: 1.0, blue: 1.0, alpha: 1.0)
        alertView.layer.cornerRadius = 10.0
        alertView.layer.borderColor = UIColor.black.cgColor
        alertView.layer.borderWidth = 1.0
        self.view.addSubview(alertView)
        return alertView
    }
    func errorAlert(_ alertText: String) {
        self.alertBG = UIView()
        self.alertBG.backgroundColor = UIColor.gray
        self.alertBG.alpha = 0.5
        self.alertBG.isOpaque = false
        self.view.addSubview(self.alertBG)
        self.alertFG = generateAlert(alertText)
        self.alertBG.snp.remakeConstraints { (make) in
            make.top.equalTo(self.view.snp.top).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.view.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.view.snp.trailing).priority(1000.0)
        }
        self.alertFG.snp.remakeConstraints { (make) in
            make.center.equalTo(self.view.snp.center).priority(1000.0)
            make.width.equalTo(self.view.snp.width).dividedBy(1.5).priority(1000.0)
            make.height.equalTo(self.view.snp.height).dividedBy(1.5).priority(1000.0)
        }
    }
    
    @IBOutlet weak var cancelOutlet: UIButton!
    @IBAction func cancelAction(_ sender: Any) {
        let size = self.view.frame.width/4
        let frame = CGRect(x: self.view.center.x-size/2, y: self.view.center.y-size/2, width: size, height: size)
        self.loading = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballClipRotatePulse, color: UIColor.white, padding: 7)
        self.view.addSubview(loading)
        loading.startAnimating()

        if (self.appDelegate.restrictionsToAdd().count <= 0) {
            if let cancelLineFunction = self.cancelLine {
                cancelLineFunction(self)
            }
            self.navigationController?.popViewController(animated: true)
        } else {
            self.getLastRestriction()
        }
        self.loading.removeFromSuperview()
        self.loading.stopAnimating()
        self.loading = nil
    }
    func addCurrentRestriction() throws -> Bool  {
        var type = -1
            if (self.curbColorValue == 2 && !self.meterOutlet.isOn) {
                guard let timelimit = self.timeLimitField.text else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                if let intTime = Int(timelimit) {
                    if (intTime < 60) {
                        // short term unmetered parking
                        type = 0
                    } else {
                        throw RestrictionError.incongruentTimeWithRestriction
                    }
                } else {
                    throw RestrictionError.timeLimitNotSpecified
                }
            } else if (self.curbColorValue == 2 && self.meterOutlet.isOn) {
                guard let timelimit = self.timeLimitField.text else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                if let intTime = Int(timelimit) {
                    if (intTime >= 60) {
                        throw RestrictionError.incongruentTimeWithRestriction
                    }
                } else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                guard let cost = self.costField.text else {
                    throw RestrictionError.costNotSpecifiedForMeter
                }
                if let floatCost = Float(cost) {
                    guard (floatCost > 0)  else {
                        throw RestrictionError.costNotSpecifiedForMeter
                    }
                } else {
                    throw RestrictionError.costNotSpecifiedForMeter
                }
                guard let per = self.permitField.text else {
                    throw RestrictionError.perNotSpecifiedForMeter
                }
                if let intPer = Int(per) {
                    if (intPer > 0 && intPer < Int(timelimit)!) {
                        type = 1
                    } else {
                        throw RestrictionError.incongruentPerTypeForMeter
                    }
                } else {
                    throw RestrictionError.perNotSpecifiedForMeter
                }
            } else if (self.curbColorValue == 0 && !self.meterOutlet.isOn && (self.permitField.text == "" || self.permitField.text == nil)) {
                guard let timelimit = self.timeLimitField.text else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                if let intTime = Int(timelimit) {
                    if (intTime >= 60) {
                        // Time Limited parking without a meter and without a permit
                        type = 2
                    } else {
                        throw RestrictionError.incongruentTimeWithRestriction
                    }
                } else {
                    throw RestrictionError.timeLimitNotSpecified
                }
            } else if (self.curbColorValue == 0 && self.meterOutlet.isOn && self.permitOutlet.selectedSegmentIndex == 1) {
                guard let timelimit = self.timeLimitField.text else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                if let intTime = Int(timelimit) {
                    if (intTime < 60) {
                        throw RestrictionError.incongruentTimeWithRestriction
                    }
                } else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                guard let cost = self.costField.text else {
                    throw RestrictionError.costNotSpecifiedForMeter
                }
                if let floatCost = Float(cost) {
                    guard (floatCost > 0)  else {
                        throw RestrictionError.costNotSpecifiedForMeter
                    }
                } else {
                    throw RestrictionError.costNotSpecifiedForMeter
                }
                guard let per = self.permitField.text else {
                    throw RestrictionError.perNotSpecifiedForMeter
                }
                if let intPer = Int(per) {
                    if (intPer > 0 && intPer <= Int(timelimit)!) {
                        type = 3
                    } else {
                        throw RestrictionError.incongruentPerTypeForMeter
                    }
                } else {
                    throw RestrictionError.perNotSpecifiedForMeter
                }
            } else if (self.curbColorValue == 0 && !self.meterOutlet.isOn && self.permitOutlet.selectedSegmentIndex == 0 && self.permitField.text != nil && self.permitField.text != "") {
                guard let timelimit = self.timeLimitField.text else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                if let intTime = Int(timelimit) {
                    if (intTime < 60) {
                        throw RestrictionError.incongruentTimeWithRestriction
                    }
                } else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                // permit exemption to time limited parking
                type = 4
            } else if (self.curbColorValue == 0 && self.meterOutlet.isOn && self.permitField.text != nil && self.permitField.text != "" && self.permitOutlet.selectedSegmentIndex == 0) {
                guard let timelimit = self.timeLimitField.text else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                if let intTime = Int(timelimit) {
                    if (intTime < 60) {
                        throw RestrictionError.incongruentTimeWithRestriction
                    }
                } else {
                    throw RestrictionError.timeLimitNotSpecified
                }
                guard let cost = self.costField.text else {
                    throw RestrictionError.costNotSpecifiedForMeter
                }
                if let floatCost = Float(cost) {
                    guard (floatCost > 0)  else {
                        throw RestrictionError.costNotSpecifiedForMeter
                    }
                } else {
                    throw RestrictionError.costNotSpecifiedForMeter
                }
                guard let per = self.permitField.text else {
                    throw RestrictionError.perNotSpecifiedForMeter
                }
                if let intPer = Int(per) {
                    if (intPer > 0 && intPer <= Int(timelimit)!) {
                        // metered parking with permit exemption
                        type = 5
                    } else {
                        throw RestrictionError.incongruentPerTypeForMeter
                    }
                } else {
                    throw RestrictionError.perNotSpecifiedForMeter
                }
            } else if (self.curbColorValue == 1 && self.npnsOutlet.selectedSegmentIndex == 0) {
                // no parking
                if (self.meterOutlet.isOn) {
                    throw RestrictionError.incongruentCurbTypeWithMeter
                }
                type = 6
            } else if (self.curbColorValue == 1 && self.permitField.text != nil && self.permitField.text != "") {
                if (self.meterOutlet.isOn) {
                    throw RestrictionError.incongruentCurbTypeWithMeter
                }
                // no parking with permit exemption
                type = 7
            } else if (self.curbColorValue == 1 && self.npnsOutlet.selectedSegmentIndex == 1) {
                if (self.meterOutlet.isOn) {
                    throw RestrictionError.incongruentCurbTypeWithMeter
                }
                // no stopping
                type = 8
            } else if (self.curbColorValue == 3) {
                if (self.meterOutlet.isOn) {
                    throw RestrictionError.incongruentCurbTypeWithMeter
                }
                // Disabled parking
                type = 10
            } else if (self.curbColorValue == 4) {
                // Yellow zone
                if (self.meterOutlet.isOn) {
                    throw RestrictionError.incongruentCurbTypeWithMeter
                }
                type = 12
            } else if (self.curbColorValue == 5) {
                if (self.meterOutlet.isOn) {
                    throw RestrictionError.incongruentCurbTypeWithMeter
                }
                //White zone
                type = 11
            }
        if (type == -1) {
            return false
        }
        var days = [true, true, true, true, true, true, true]
        if (!self.daysSwitchOutlet.isOn) {
            days = [self.sunSwitchOutlet.isOn, self.monSwitchOutlet.isOn, self.tueSwitchOutlet.isOn, self.wedSwitchOutlet.isOn, self.thuSwitchOutlet.isOn, self.friSwitchOutlet.isOn, self.satSwitchOutlet.isOn]
        }
        var weeks = [true, true, true, true]
        if (!self.everyWeekSwitchOutlet.isOn) {
            weeks = [self.firstWeekOutlet.isOn, self.secondWeekOutlet.isOn, self.thirdWeekOutlet.isOn, self.fourthWeekOutlet.isOn]
        }
        var months = [true, true, true, true, true, true, true, true, true, true, true, true]
        if (!self.everyMonthOutlet.isOn) {
            months = [self.janOutlet.isOn, self.febOutlet.isOn, self.marOutlet.isOn, self.aprOutlet.isOn, self.mayOutlet.isOn, self.junOutlet.isOn, self.julOutlet.isOn, self.augOutlet.isOn, self.sepOutlet.isOn, self.octOutlet.isOn, self.novOutlet.isOn, self.decOutlet.isOn]
        }
        var start = 0
        var end = 1440
        if (!self.allDaySwitchOutlet.isOn) {
            start = startTimePicker.selectedRow(inComponent: 0) * 60 + startTimePicker.selectedRow(inComponent: 1)
            end = endTimePicker.selectedRow(inComponent: 0) * 60 + endTimePicker.selectedRow(inComponent: 1)
        }
        let restriction = Restriction(type: type, days: days, weeks: weeks, months: months, from: start, to: end, angle: self.angleOutlet.selectedSegmentIndex, holidays: self.holidaysSwitch.isOn, vehicle: self.vehicleType.selectedSegmentIndex, side: self.sideOutlet.selectedSegmentIndex, limit: (self.timeLimitField.text != nil && self.timeLimitField.text != "0") ? Int(self.timeLimitField.text!) : nil, cost: self.costField.text != nil && self.costField.text != "0.0" ? Float(self.costField.text!) : nil, per: self.perField.text != nil ? Int(self.perField.text!) : nil, permit: self.permitField.text != nil && self.permitField.text != "" ? self.permitField.text : nil)
        self.appDelegate.addRestriction(restriction)
        return true
    }
    func resetAllDay() {
        self.startTimePicker.selectRow(8, inComponent: 0, animated: true)
        self.startTimePicker.selectRow(0, inComponent: 1, animated: true)
        self.endTimePicker.selectRow(10, inComponent: 0, animated: true)
        self.endTimePicker.selectRow(0, inComponent: 1, animated: true)
    }
    func resetDays() {
        self.sunSwitchOutlet.setOn(false, animated: false)
        self.monSwitchOutlet.setOn(false, animated: false)
        self.tueSwitchOutlet.setOn(false, animated: false)
        self.wedSwitchOutlet.setOn(false, animated: false)
        self.thuSwitchOutlet.setOn(false, animated: false)
        self.friSwitchOutlet.setOn(false, animated: false)
        self.satSwitchOutlet.setOn(false, animated: false)
    }
    func resetWeeks() {
        self.firstWeekOutlet.setOn(false, animated: false)
        self.secondWeekOutlet.setOn(false, animated: false)
        self.thirdWeekOutlet.setOn(false, animated: false)
        self.fourthWeekOutlet.setOn(false, animated: false)
    }
    func resetMonths() {
        self.janOutlet.setOn(false, animated: false)
        self.febOutlet.setOn(false, animated: false)
        self.marOutlet.setOn(false, animated: false)
        self.aprOutlet.setOn(false, animated: false)
        self.mayOutlet.setOn(false, animated: false)
        self.junOutlet.setOn(false, animated: false)
        self.julOutlet.setOn(false, animated: false)
        self.augOutlet.setOn(false, animated: false)
        self.sepOutlet.setOn(false, animated: false)
        self.octOutlet.setOn(false, animated: false)
        self.novOutlet.setOn(false, animated: false)
        self.decOutlet.setOn(false, animated: false)
    }
    
    func getLastRestriction() {
        self.createCentralViews()
        self.setupCentralViews()
        if let restriction = self.appDelegate.popRestriction() {
            if let limit = restriction.timeLimit {
                self.timeLimitField.text = String(limit)
            }
            if let cost = restriction.cost {
                self.costField.text = String(cost)
                self.meterOutlet.setOn(true, animated: true)
            }
            if let per = restriction.per {
                self.perField.text = String(per)
            }
            if (restriction.days.contains(false)) {
                self.daysSwitchOutlet.setOn(false, animated: true)
                self.sunSwitchOutlet.setOn(restriction.days[0], animated: true)
                self.monSwitchOutlet.setOn(restriction.days[1], animated: true)
                self.tueSwitchOutlet.setOn(restriction.days[2], animated: true)
                self.wedSwitchOutlet.setOn(restriction.days[3], animated: true)
                self.thuSwitchOutlet.setOn(restriction.days[4], animated: true)
                self.friSwitchOutlet.setOn(restriction.days[5], animated: true)
                self.satSwitchOutlet.setOn(restriction.days[6], animated: true)
            }
            if (restriction.weeks.contains(false)) {
                self.everyWeekSwitchOutlet.setOn(false, animated: true)
                self.firstWeekOutlet.setOn(restriction.weeks[0], animated: true)
                self.secondWeekOutlet.setOn(restriction.weeks[1], animated: true)
                self.thirdWeekOutlet.setOn(restriction.weeks[2], animated: true)
                self.fourthWeekOutlet.setOn(restriction.weeks[3], animated: true)
            }
            if (restriction.months.contains(false)) {
                self.everyMonthOutlet.setOn(false, animated: false)
                self.janOutlet.setOn(restriction.months[0], animated: false)
                self.febOutlet.setOn(restriction.months[1], animated: false)
                self.marOutlet.setOn(restriction.months[2], animated: false)
                self.aprOutlet.setOn(restriction.months[3], animated: false)
                self.mayOutlet.setOn(restriction.months[4], animated: false)
                self.junOutlet.setOn(restriction.months[5], animated: false)
                self.julOutlet.setOn(restriction.months[6], animated: false)
                self.augOutlet.setOn(restriction.months[7], animated: false)
                self.sepOutlet.setOn(restriction.months[8], animated: false)
                self.octOutlet.setOn(restriction.months[9], animated: false)
                self.novOutlet.setOn(restriction.months[10], animated: false)
                self.decOutlet.setOn(restriction.months[11], animated: false)
            }
            if (restriction.fromTime != 0 || restriction.toTime != 1440) {
                let s_hours = Int(floor(Double(restriction.fromTime) / 60.0))
                let s_minutes = restriction.fromTime - (60 * s_hours)
                let e_hours = Int(floor(Double(restriction.toTime) / 60.0))
                let e_minutes = restriction.toTime - (60 * s_hours)
                self.allDaySwitchOutlet.setOn(false, animated: true)
                startTimePicker.selectRow(s_hours, inComponent: 0, animated: true)
                startTimePicker.selectRow(s_minutes, inComponent: 1, animated: true)
                endTimePicker.selectRow(e_hours, inComponent: 0, animated: true)
                endTimePicker.selectRow(e_minutes, inComponent: 1, animated: true)
            }
            if (restriction.permit != nil && restriction.permit != "") {
                self.permitField.text = restriction.permit!
                self.permitOutlet.selectedSegmentIndex = 0
            }
            
            
            self.vehicleType.selectedSegmentIndex = restriction.vehicleType
            self.holidaysSwitch.setOn(restriction.enforcedHolidays, animated: true)
            self.angleOutlet.selectedSegmentIndex = restriction.angle
            self.angleAction(self)
            switch(restriction.type) {
            case 0:
                fallthrough
            case 1:
                self.greenCurbAction(self)
                break
            case 2:
                fallthrough
            case 3:
                fallthrough
            case 4:
                fallthrough
            case 5:
                self.grayCurbAction(self)
            case 6:
                fallthrough
            case 7:
                fallthrough
            case 8:
                self.redCurbAction(self)
            case 10:
                self.blueCurbAction(self)
            case 11:
                self.whiteCurbAction(self)
            case 12:
                self.yellowCurbAction(self)
            default:
                break
            }
        } else {
            // do nothing
        }
        self.setupCentralViews()
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
    
    @IBOutlet weak var allDaySwitchOutlet: UISwitch!
    @IBAction func allDaySwitchAction(_ sender: Any) {
        self.resetAllDay()
        self.setupCentralViews()
    }
    @IBOutlet weak var allDayLabel: UILabel!
    @IBOutlet weak var timeView: UIView!
    
    @IBOutlet weak var startTimeHeading: UILabel!
    @IBOutlet weak var startTimePicker: UIPickerView!

    @IBOutlet weak var endTimeHeading: UILabel!
    @IBOutlet weak var endTimePicker: UIPickerView!
    
    @IBOutlet weak var daysSwitchOutlet: UISwitch!
    @IBAction func daysSwitchAction(_ sender: Any) {
        self.resetDays()
        self.setupCentralViews()
    }
    @IBOutlet weak var daysView: UIScrollView!
    @IBOutlet weak var sunLabel: UILabel!
    @IBOutlet weak var sunSwitchOutlet: UISwitch!
    @IBAction func sunSwitchAction(_ sender: Any) {
        
    }
    @IBOutlet weak var monLabel: UILabel!
    @IBOutlet weak var monSwitchOutlet: UISwitch!
    @IBAction func monSwitchAction(_ sender: Any) {
    }
    @IBOutlet weak var tueLabel: UILabel!
    @IBOutlet weak var tueSwitchOutlet: UISwitch!
    @IBAction func tueSwitchAction(_ sender: Any) {
    }
    @IBOutlet weak var wedLabel: UILabel!
    @IBOutlet weak var wedSwitchOutlet: UISwitch!
    @IBAction func wedSwitchAction(_ sender: Any) {
    }
    @IBOutlet weak var thuLabel: UILabel!
    @IBOutlet weak var thuSwitchOutlet: UISwitch!
    @IBAction func thuSwitchAction(_ sender: Any) {
    }
    @IBOutlet weak var friLabel: UILabel!
    @IBOutlet weak var friSwitchOutlet: UISwitch!
    @IBAction func friSwitchAction(_ sender: Any) {
    }
    @IBOutlet weak var satLabel: UILabel!
    @IBOutlet weak var satSwitchOutlet: UISwitch!
    @IBAction func satSwitchAction(_ sender: Any) {
    }
    @IBOutlet weak var everyDayLabel: UILabel!
    
    @IBOutlet weak var everyWeekSwitchOutlet: UISwitch!
    @IBAction func everyWeekSwitchAction(_ sender: Any) {
        self.resetWeeks()
        self.setupCentralViews()
    }
    @IBOutlet weak var everyWeekLabel: UILabel!
    @IBOutlet weak var weeksView: UIScrollView!
    @IBOutlet weak var firstWeekOutlet: UISwitch!
    @IBAction func firstWeekAction(_ sender: Any) {
    }
    @IBOutlet weak var firstWeekLabel: UILabel!
    @IBOutlet weak var secondWeekOutlet: UISwitch!
    @IBAction func secondWeekAction(_ sender: Any) {
    }
    @IBOutlet weak var secondWeekLabel: UILabel!
    @IBOutlet weak var thirdWeekOutlet: UISwitch!
    @IBAction func thirdWeekAction(_ sender: Any) {
    }
    @IBOutlet weak var thirdWeekLabel: UILabel!
    @IBOutlet weak var fourthWeekOutlet: UISwitch!
    @IBAction func fourthWeekAction(_ sender: Any) {
    }
    @IBOutlet weak var fourthWeekLabel: UILabel!
    @IBOutlet weak var everyMonthOutlet: UISwitch!
    @IBAction func everyMonthAction(_ sender: Any) {
        self.resetMonths()
        self.setupCentralViews()
    }
    @IBOutlet weak var everyMonthLabel: UILabel!
    @IBOutlet weak var monthsView: UIScrollView!
    @IBOutlet weak var janOutlet: UISwitch!
    @IBAction func janAction(_ sender: Any) {
    }
    @IBOutlet weak var janLabel: UILabel!
    
    @IBOutlet weak var febOutlet: UISwitch!
    @IBAction func febAction(_ sender: Any) {
    }
    @IBOutlet weak var febLabel: UILabel!
    @IBOutlet weak var marOutlet: UISwitch!
    @IBAction func marAction(_ sender: Any) {
    }
    @IBOutlet weak var marLabel: UILabel!
    @IBOutlet weak var aprOutlet: UISwitch!
    @IBAction func aprAction(_ sender: Any) {
    }
    @IBOutlet weak var aprLabel: UILabel!
    @IBOutlet weak var mayOutlet: UISwitch!
    @IBAction func mayAction(_ sender: Any) {
    }
    @IBOutlet weak var mayLabel: UILabel!
    @IBOutlet weak var junOutlet: UISwitch!
    @IBAction func junAction(_ sender: Any) {
    }
    @IBOutlet weak var junLabel: UILabel!
    @IBOutlet weak var julOutlet: UISwitch!
    @IBAction func julAction(_ sender: Any) {
    }
    @IBOutlet weak var julLabel: UILabel!
    @IBOutlet weak var augOutlet: UISwitch!
    @IBAction func augAction(_ sender: Any) {
    }
    @IBOutlet weak var augLabel: UILabel!
    @IBOutlet weak var sepOutlet: UISwitch!
    @IBAction func sepAction(_ sender: Any) {
    }
    @IBOutlet weak var sepLabel: UILabel!
    @IBOutlet weak var octOutlet: UISwitch!
    @IBAction func octAction(_ sender: Any) {
    }
    @IBOutlet weak var octLabel: UILabel!
    @IBOutlet weak var novOutlet: UISwitch!
    @IBAction func novAction(_ sender: Any) {
    }
    @IBOutlet weak var novLabel: UILabel!
    @IBOutlet weak var decOutlet: UISwitch!
    @IBAction func decAction(_ sender: Any) {
    }
    @IBOutlet weak var decLabel: UILabel!

    
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
    let angleImageView = UIImageView(image: UIImage(named: "parallel"))
    @IBOutlet weak var angleHeading: UILabel!
    @IBAction func angleAction(_ sender: Any) {
        if (angleOutlet.selectedSegmentIndex == 0) {
            self.angleImageView.image = UIImage(named: "parallel")
        } else if (angleOutlet.selectedSegmentIndex == 1) {
            self.angleImageView.image = UIImage(named: "headin")
        } else {
            self.angleImageView.image = UIImage(named: "angled")
        }
        self.setupCentralViews()
    }
    @IBOutlet weak var angleOutlet: UISegmentedControl!
    
    @IBOutlet weak var sideLabel: UILabel!
    @IBOutlet weak var sideOutlet: UISegmentedControl!
    
    var contentInsetOriginal:UIEdgeInsets!
    var vehicleTypeHeading: UILabel = UILabel()
    var vehicleType:UISegmentedControl = UISegmentedControl(items: ["all/any", "car", "motorcycle", "5+ tires", "camper/living"])
    var holidaysSwitch: UISwitch = UISwitch()
    var holidaysLabel: UILabel = UILabel()
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.isEnabled = false;
        scrollView.panGestureRecognizer.isEnabled = true;
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        
    }
    
    func createCentralViews() {
        self.curbView.isScrollEnabled = true
        self.curbView.isUserInteractionEnabled = true
        self.curbView.isExclusiveTouch = false
        self.curbView.isPagingEnabled = false
        //self.curbView.delegate = self
        self.scrollView.isExclusiveTouch = false
        self.scrollView.isScrollEnabled = true
        self.scrollView.isUserInteractionEnabled = true
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.delegate = self
        self.scrollView.isPagingEnabled = true
        self.scrollView.scrollsToTop = false
        self.meterView.isExclusiveTouch = false
        self.meterView.isScrollEnabled = false
        self.meterView.isUserInteractionEnabled = true
        //self.meterView.delegate = self
        self.meterView.isPagingEnabled = false
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
        self.npnsOutlet.selectedSegmentIndex = 0
        self.meterOutlet.setOn(false, animated: true)
        self.currencyOutlet.selectedSegmentIndex = 0
        self.angleOutlet.selectedSegmentIndex = 0
        self.permitOutlet.selectedSegmentIndex = 1
        self.permitField.returnKeyType = .done
        self.permitField.delegate = self
        self.permitField.text = nil
        self.permitField.tag = 0
        self.costField.returnKeyType = .next
        self.costField.delegate = self
        self.costField.tag = 1
        self.costField.text = nil
        self.perField.returnKeyType = .done
        self.perField.tag = 2
        self.perField.delegate = self
        self.perField.text = "0"
        self.timeLimitField.returnKeyType = .done
        self.timeLimitField.tag = 3
        self.timeLimitField.delegate = self
        self.timeLimitField.text = "0"
        self.startTimeDelegate = TimeDelegateData()
        self.endTimeDelegate = TimeDelegateData()
        self.grayCurbAction(self)
        self.meterOutlet.setOn(false, animated: true)
        self.costField.text = nil
        self.perField.text = nil
        self.startTimePicker.delegate = self.startTimeDelegate
        self.startTimePicker.dataSource = self.startTimeDelegate
        self.endTimePicker.dataSource = self.endTimeDelegate
        self.endTimePicker.delegate = self.endTimeDelegate
        self.allDaySwitchOutlet.setOn(true, animated: true)
        self.resetAllDay()
        self.daysSwitchOutlet.setOn(true, animated: true)
        self.resetDays()
        self.everyWeekSwitchOutlet.setOn(true, animated: true)
        self.resetWeeks()
        self.everyMonthOutlet.setOn(true, animated: true)
        self.resetMonths()
        self.angleImageView.image = UIImage(named: "parallel")
        self.angleOutlet.selectedSegmentIndex = 0
        self.angleAction(self)
        self.scrollView.addSubview(self.angleImageView)
        self.holidaysSwitch.setOn(true, animated: true)
        self.holidaysLabel.text = "Enforced on holidays"
        self.holidaysLabel.textColor = UIColor.white
        self.vehicleType.selectedSegmentIndex = 0
        self.vehicleType.addTarget(self, action: #selector(self.changeVehicleType), for: .touchUpInside)
        self.vehicleTypeHeading.text = "Rule pertains to:"
        self.vehicleTypeHeading.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        self.vehicleTypeHeading.textColor = UIColor.white
        self.scrollView.addSubview(self.holidaysSwitch)
        self.scrollView.addSubview(self.holidaysLabel)
        self.scrollView.addSubview(self.vehicleTypeHeading)
        self.scrollView.addSubview(self.vehicleType)
    }
    @objc func changeVehicleType(_ sender: Any) {
        
    }
    func setupCentralViews() {
        if (self.angleImageView.superview != self.scrollView) {
            self.scrollView.addSubview(self.angleImageView)
            self.scrollView.addSubview(self.holidaysSwitch)
            self.scrollView.addSubview(self.holidaysLabel)
            self.scrollView.addSubview(self.vehicleTypeHeading)
            self.scrollView.addSubview(self.vehicleType)
        }
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
            make.width.equalTo(self.scrollView.snp.width).dividedBy(1.25).priority(1000.0)
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
            if (self.curbColorValue == 1) {
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
            if (self.curbColorValue == 1 || self.curbColorValue == 0) {
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
            if (permitOutlet.selectedSegmentIndex == 0 && (self.curbColorValue == 1 || self.curbColorValue == 0)) {
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
            if (permitOutlet.selectedSegmentIndex == 0 && (self.curbColorValue == 1 || self.curbColorValue == 0)) {
                self.permitLabel.isHidden = false
                make.height.equalTo(45).priority(1000.0)
            } else {
                self.permitLabel.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.sideLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.permitField.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.permitField.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
        }
        self.sideOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.sideLabel.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.sideLabel.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            make.height.equalTo(45).priority(1000.0)
        }
        self.meterOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.sideOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.sideOutlet.snp.leading).priority(1000.0)
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
        self.allDaySwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.meterView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.meterOutlet.snp.leading).priority(1000.0)
        }
        self.allDayLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.meterView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.allDaySwitchOutlet.snp.trailing).offset(10).priority(1000.0)
            make.height.equalTo(self.allDaySwitchOutlet.snp.height).priority(1000.0)
        }
        self.timeView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.allDaySwitchOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.allDaySwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            if (!self.allDaySwitchOutlet.isOn) {
                self.timeView.isHidden = false
                make.height.equalTo(220).priority(1000.0)
            } else {
                self.timeView.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.timeView.backgroundColor = UIColor.clear
        self.startTimeHeading.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.timeView.snp.top).priority(1000.0)
            make.height.equalTo(24).priority(1000.0)
            make.width.equalTo(self.timeView.snp.width).priority(1000.0)
        })
        self.startTimePicker.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.startTimeHeading.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.timeView.snp.leading).priority(1000.0)
            make.width.equalTo(self.timeView.snp.width).priority(1000.0)
            make.height.equalTo(70).priority(1000.0)
        })
        self.startTimePicker.backgroundColor = UIColor.gray
        self.endTimeHeading.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.startTimePicker.snp.bottom).offset(10).priority(1000.0)
            make.height.equalTo(24).priority(1000.0)
            make.width.equalTo(self.timeView.snp.width).priority(1000.0)
        })
        self.endTimePicker.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.endTimeHeading.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.timeView.snp.leading).priority(1000.0)
            make.width.equalTo(self.timeView.snp.width).priority(1000.0)
            make.height.equalTo(70).priority(1000.0)
        })
        self.endTimePicker.backgroundColor = UIColor.gray
        self.daysSwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.timeView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.timeView.snp.leading).priority(1000.0)
        }
        self.everyDayLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.daysSwitchOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.daysSwitchOutlet.snp.trailing).offset(10).priority(1000.0)
            make.height.equalTo(self.daysSwitchOutlet.snp.height).priority(1000.0)
        }
        self.daysView.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.daysSwitchOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.daysSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            if (!self.daysSwitchOutlet.isOn) {
                self.daysView.isHidden = false
                make.height.equalTo(60).priority(1000.0)
            } else {
                self.daysView.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        })
        self.sunSwitchOutlet.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.daysView.snp.leading).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        })
        self.sunLabel.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.sunSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.sunSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.sunSwitchOutlet.snp.width).priority(1000.0)
        })
        self.monSwitchOutlet.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.sunSwitchOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        })
        self.monLabel.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.monSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.monSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.monSwitchOutlet.snp.width).priority(1000.0)
        })
        self.tueSwitchOutlet.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.monSwitchOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        })
        self.tueLabel.snp.remakeConstraints ({ (make) in
            make.top.equalTo(self.tueSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.tueSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.tueSwitchOutlet.snp.width).priority(1000.0)
        })
        self.wedSwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.tueSwitchOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        }
        self.wedLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.wedSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.wedSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.wedSwitchOutlet.snp.width).priority(1000.0)
        }
        self.thuSwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.wedSwitchOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        }
        self.thuLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.thuSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.thuSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.thuSwitchOutlet.snp.width).priority(1000.0)
        }
        self.friSwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.thuSwitchOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        }
        self.friLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.friSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.friSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.friSwitchOutlet.snp.width).priority(1000.0)
        }
        self.satSwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.daysView.snp.top).priority(1000.0)
            make.leading.equalTo(self.friSwitchOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.daysView.snp.width).dividedBy(7).priority(1000.0)
        }
        self.satLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.satSwitchOutlet.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.satSwitchOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.satSwitchOutlet.snp.width).priority(1000.0)
        }

        self.everyWeekSwitchOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.daysView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.daysView.snp.leading).priority(1000.0)
        }
        self.everyWeekLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.everyWeekSwitchOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.everyWeekSwitchOutlet.snp.trailing).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailing).priority(1000.0)
        }
        self.weeksView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.everyWeekSwitchOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.everyWeekSwitchOutlet.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailing).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            if (!everyWeekSwitchOutlet.isOn) {
                self.weeksView.isHidden = false
                make.height.equalTo(60).priority(1000.0)
            } else {
                self.weeksView.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.firstWeekOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.weeksView.snp.top).priority(1000.0)
            make.leading.equalTo(self.weeksView.snp.leading).priority(1000.0)
            make.width.equalTo(self.weeksView.snp.width).dividedBy(4).priority(1000.0)
        }
        self.firstWeekLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.firstWeekOutlet.snp.bottom).offset(5).priority(1000)
            make.leading.equalTo(self.firstWeekOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.firstWeekOutlet.snp.width).priority(1000.0)
        }
        self.secondWeekOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.weeksView.snp.top).priority(1000.0)
            make.leading.equalTo(self.firstWeekOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.weeksView.snp.width).dividedBy(4).priority(1000.0)
        }
        self.secondWeekLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.secondWeekOutlet.snp.bottom).offset(5).priority(1000)
            make.leading.equalTo(self.secondWeekOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.secondWeekOutlet.snp.width).priority(1000.0)
        }
        self.thirdWeekOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.weeksView.snp.top).priority(1000.0)
            make.leading.equalTo(self.secondWeekOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.weeksView.snp.width).dividedBy(4).priority(1000.0)
        }
        self.thirdWeekLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.thirdWeekOutlet.snp.bottom).offset(5).priority(1000)
            make.leading.equalTo(self.thirdWeekOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.thirdWeekOutlet.snp.width).priority(1000.0)
        }
        self.fourthWeekOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.weeksView.snp.top).priority(1000.0)
            make.leading.equalTo(self.thirdWeekOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.weeksView.snp.width).dividedBy(4).priority(1000.0)
        }
        self.fourthWeekLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.fourthWeekOutlet.snp.bottom).offset(5).priority(1000)
            make.leading.equalTo(self.fourthWeekOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.fourthWeekOutlet.snp.width).priority(1000.0)
        }
        self.everyMonthOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.weeksView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.weeksView.snp.leading).priority(1000.0)
        }
        self.everyMonthLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.everyMonthOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.everyMonthOutlet.snp.trailing).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailing).priority(1000.0)
        }
        self.monthsView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.everyMonthOutlet.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.everyMonthOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
            if (!everyMonthOutlet.isOn) {
                self.monthsView.isHidden = false
                make.height.equalTo(120).priority(1000.0)
            } else {
                self.monthsView.isHidden = true
                make.height.equalTo(0).priority(1000.0)
            }
        }
        self.janOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.monthsView.snp.top).priority(1000.0)
            make.leading.equalTo(self.monthsView.snp.leading).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.janLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.janOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.janOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.janOutlet.snp.width).priority(1000.0)
        }
        self.febOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.janOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.janOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.febLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.febOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.febOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.febOutlet.snp.width).priority(1000.0)
        }
        self.marOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.febOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.febOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.marLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.marOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.marOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.marOutlet.snp.width).priority(1000.0)
        }
        self.aprOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.marOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.marOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.aprLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.aprOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.aprOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.aprOutlet.snp.width).priority(1000.0)
        }
        self.mayOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.aprOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.aprOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.mayLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.mayOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.mayOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.mayOutlet.snp.width).priority(1000.0)
        }
        self.junOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.mayOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.mayOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.junLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.junOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.junOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.junOutlet.snp.width).priority(1000.0)
        }
        self.julOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.janLabel.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.monthsView.snp.leading).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.julLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.julOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.julOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.julOutlet.snp.width).priority(1000.0)
        }
        self.augOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.julOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.julOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.augLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.augOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.augOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.augOutlet.snp.width).priority(1000.0)
        }
        self.sepOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.augOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.augOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.sepLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.sepOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.sepOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.sepOutlet.snp.width).priority(1000.0)
        }
        self.octOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.sepOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.sepOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.octLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.octOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.octOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.octOutlet.snp.width).priority(1000.0)
        }
        self.novOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.octOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.octOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.novLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.novOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.novOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.novOutlet.snp.width).priority(1000.0)
        }
        self.decOutlet.snp.remakeConstraints { (make) in
            make.top.equalTo(self.novOutlet.snp.top).priority(1000.0)
            make.leading.equalTo(self.novOutlet.snp.trailing).priority(1000.0)
            make.width.equalTo(self.monthsView.snp.width).dividedBy(6).priority(1000.0)
        }
        self.decLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(self.decOutlet.snp.bottom).priority(1000.0)
            make.leading.equalTo(self.decOutlet.snp.leading).priority(1000)
            make.width.equalTo(self.decOutlet.snp.width).priority(1000.0)
        }
        self.timeLimitField.snp.remakeConstraints { (make) in
            make.top.equalTo(self.monthsView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.monthsView.snp.leading).priority(1000.0)
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
        self.angleImageView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.angleOutlet.snp.bottom).offset(10).priority(1000.0)
            make.centerX.equalTo(self.angleOutlet.snp.centerX).priority(1000.0)
            make.width.equalTo(self.angleOutlet.snp.width).dividedBy(3).priority(1000.0)
            make.height.equalTo(self.angleImageView.snp.width).multipliedBy(1.55).priority(1000.0)
        }
        self.vehicleTypeHeading.snp.remakeConstraints { (make) in
            make.top.equalTo(self.angleImageView.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.angleOutlet.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
        }
        self.vehicleType.snp.remakeConstraints { (make) in
            make.top.equalTo(self.vehicleTypeHeading.snp.bottom).offset(5).priority(1000.0)
            make.leading.equalTo(self.vehicleTypeHeading.snp.leading).priority(1000.0)
            make.width.equalTo(self.scrollView.snp.width).priority(1000.0)
        }
        self.holidaysSwitch.snp.remakeConstraints { (make) in
            make.top.equalTo(self.vehicleType.snp.bottom).offset(10).priority(1000.0)
            make.leading.equalTo(self.vehicleType.snp.leading).priority(1000.0)
        }
        self.holidaysLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.holidaysSwitch.snp.centerY).priority(1000.0)
            make.leading.equalTo(self.holidaysSwitch.snp.trailing).offset(10).priority(1000.0)
            make.trailing.equalTo(self.scrollView.snp.trailing).priority(1000.0)
            make.height.equalTo(self.holidaysSwitch.snp.height).priority(1000.0)
        }
        self.viewWillLayoutSubviews()
    }
    override func viewWillLayoutSubviews(){
        super.viewWillLayoutSubviews()
        scrollView.contentSize = CGSize(width: self.view.frame.width, height: 1600)
        curbView.contentSize = CGSize(width: self.view.frame.width/1.25, height: 360)
        //meterView.contentSize = CGSize(width: self.view.frame.width, height: 300)
        if (self.loading != nil) {
            self.loading.stopAnimating()
            self.loading.removeFromSuperview()
        }
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
        self.permitField.endEditing(true)
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
            //self.scrollView.setContentOffset(CGPoint(x:contentInsetOriginal.left, y:0.0), animated: true)
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
