//
//  AlarmViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import EventKit
import UserNotifications
import RxCocoa
import RxSwift
import SnapKit

class AlarmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var menuTableViewController: UITableViewController!
    var disposeBag = DisposeBag()
    var timer: Observable<Int>!
    var viewSize: CGSize!
    
    @IBOutlet weak var timerLabel: UILabel!
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    @IBOutlet weak var containerView: UIView!
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            return 25
        } else {
            return 61
        }
    }

    @IBOutlet weak var menuButtonOutlet: UIButton!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBAction func menuButton(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var value: String!
        if (component == 0 && row == 0) {
            value = "Hours"
        } else if (component == 1 && row == 0) {
            value = "Minutes"
        } else {
            value = String(row-1)
        }
        let attributes : [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font:UIFont(name: "Georgia", size: 13.0)!,
            NSAttributedStringKey.foregroundColor:UIColor.white
        ]
        let title = NSAttributedString(string: value!, attributes: attributes)
        return title
    }
    
    
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var startButton: UIButton!
    @IBAction func startPressed(_ sender: Any) {
        if (appDelegate.notificationDelegate.timerIsRunning.value) {
            // stop the timer
            appDelegate.notificationDelegate.timerIsRunning.value = false
            self.timer = nil
            self.disposeBag = DisposeBag()
            appDelegate.notificationDelegate.timerValue = 0
            appDelegate.removeNotifications()
            self.picker.isHidden = false
            self.timerLabel.isHidden = true
            self.startButton.setTitle("Start timer", for: .normal)
        } else {
            self.timerLabel.text = "Timer starting"
            // start the timer
            var hours = picker.selectedRow(inComponent: 0)
            if (hours >= 2 ) {
                hours -= 1
            } else {
                hours = 0
            }
            var minutes = picker.selectedRow(inComponent: 1)
            if (minutes >= 2) {
                minutes -= 1
            } else {
                minutes = 0
            }
            let inSeconds = Int(hours * (60*60) + minutes * 60)
            if (inSeconds <= 0) {
                return // just stop... it's silly to go on
            }
            if (appDelegate.localNotificationsAllowed) {
                let futureDate = Date().addingTimeInterval(TimeInterval(inSeconds))
                // local notifications are allowed so really set the notification!
                let content = UNMutableNotificationContent()
                content.title = "Please move your car"
                content.body = "The \(hours) hours and \(minutes) minutes you set have elapsed. Set for: \(futureDate.timeIntervalSince1970)"
                content.sound = UNNotificationSound(named: "railroad.aiff")
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(inSeconds), repeats: false)
                let identifier = "CurbmapAlarmLocalNotification"
                let request = UNNotificationRequest(identifier: identifier,
                                                    content: content, trigger: trigger)
                appDelegate.center.add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        // Something went wrong
                        print(error.localizedDescription)
                    } else {
                        // completed adding request
                        // start the local timer
                        self.checkTimeLeft()
                    }
                })
            } else {
                // just launch the timer in the current window and if you leave... oh well
                let alert = UIAlertController(title: "Timer settings", message: "Without notifications allowed, timer will not work.", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func startTimer() {
        self.picker.isHidden = true
        self.timerLabel.isHidden = false
        self.startButton.setTitle("Cancel timer", for: .normal)
        print("start timer? \(self.appDelegate.notificationDelegate.timerIsRunning.value)")
        guard self.appDelegate.notificationDelegate.timerIsRunning.value == false else { return }
        self.appDelegate.notificationDelegate.timerIsRunning.value = true
        self.timer = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
        self.timer.subscribe(onNext: { (sec) in
            self.tick()
        }).disposed(by: disposeBag)
        self.appDelegate.notificationDelegate.timerAllotted?.asObservable().subscribe(onNext: { (newValue) in
            self.setRemainingTime(newValue)
        })
    }
    
    @objc func setupCentralViews(_ firstTime: Int) {
        viewSize = self.view.frame.size
        if ((firstTime != 1 && firstTime != 2) &&
            ((!UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width > viewSize.height) ||
                (UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width < viewSize.height))) {
            viewSize = CGSize(width: viewSize.height, height: viewSize.width)
        }
        print("XXXX: \(viewSize)")

        self.menuButtonOutlet.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.width.equalTo(64).priority(1000.0)
            make.height.equalTo(64).priority(1000.0)
        }
        // They should call it wasPortrait
        self.containerView.snp.remakeConstraints({(make) in
            make.leading.equalTo(self.menuButtonOutlet.snp.leading).priority(1000.0)
            make.top.equalTo(self.menuButtonOutlet.snp.bottom).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin)
            if (viewSize.width < viewSize.height) {
                make.width.equalTo(viewSize.width/1.5).priority(1000.0)
            } else {
                make.width.equalTo(viewSize.width/2.0).priority(1000.0)
            }
        })
        self.picker.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.menuButtonOutlet.snp.bottom).priority(1000.0)
            make.trailing.equalTo(self.view.snp.trailingMargin).priority(1000.0)
            make.height.equalTo(viewSize.height/2)
        }
        self.startButton.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.picker.snp.centerX).priority(1000.0)
            make.top.equalTo(self.picker.snp.bottom).offset(10).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
            make.width.equalTo(125).priority(1000.0)
        }
        self.timerLabel.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).priority(1000.0)
            make.top.equalTo(self.menuButtonOutlet.snp.bottom).priority(1000.0)
            make.trailing.equalTo(self.view.snp.trailingMargin).priority(1000.0)
            make.height.equalTo(viewSize.height/2)
        }

        self.view.layoutSubviews()
        self.view.layoutIfNeeded()
    }
    
    @objc func tick() {
        print("Do we get called")
        self.appDelegate.notificationDelegate.timerValue -= 1
        self.appDelegate.notificationDelegate.trigger_TimerAllottedUpdate(newtimerValue: self.appDelegate.notificationDelegate.timerValue)
        if (self.appDelegate.notificationDelegate.timerValue <= 0) {
            //sound the alarm
            self.disposeBag = DisposeBag()
            self.appDelegate.notificationDelegate.timerIsRunning.value = false
            self.timerLabel.text = "Timer finished :-("
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.dataSource = self
        self.picker.delegate = self
        self.picker.selectRow(1, inComponent: 0, animated: true)
        self.picker.selectRow(1, inComponent: 1, animated: true)
        appDelegate.notificationDelegate.timerController = self
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            self.setupCentralViews(1)
        } else {
            self.setupCentralViews(2)
        }
        // Do any additional setup after loading the view.
    }
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.setupCentralViews(0)
    }

    override func viewWillAppear(_ animated: Bool) {
            self.checkTimeLeft()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.disposeBag = DisposeBag()
        self.appDelegate.notificationDelegate.timerIsRunning.value = false
    }
    
    @objc func checkTimeLeft() {
        if (appDelegate.localNotificationsAllowed) {
            appDelegate.center.getPendingNotificationRequests(completionHandler: appDelegate.notificationDelegate.gotPendingNotification)
        }
    }
    
    @objc func setRemainingTime(_ timeRemaining: Int) {
        let hours = Int(floor(Double(timeRemaining) / (60.0*60.0)))
        let minutes = Int(floor((Double(timeRemaining) - (Double(hours) * (60.0*60.0))) / 60.0))
        let seconds = Int(floor(Double(timeRemaining) - (Double(hours) * 60.0*60.0) - (Double(minutes) * 60.0)))
        timerLabel.text = String(format:"%02d : %02d : %02d", hours, minutes, seconds)
        self.timerLabel.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UITableViewController,
            segue.identifier == "ShowMenuFromAlarm" {
            self.menuTableViewController = vc
        }
    }

}
