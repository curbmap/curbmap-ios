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

class AlarmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var menuTableViewController: UITableViewController!
    var disposeBag = DisposeBag()
    var timer: Observable<Int>!
    
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

    var menuOpen = false
    // Hide table view tap on map or button
    @IBAction func menuButton(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (component == 0 && row == 0) {
            return "Hours"
        } else if (component == 1 && row == 0) {
            return "Minutes"
        } else {
            return String(row-1)
        }
    }
    
    
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var startButton: UIButton!
    @IBAction func startPressed(_ sender: Any) {
        print("start pressed \(appDelegate.notificationDelegate.timerIsRunning.value)")
        if (appDelegate.notificationDelegate.timerIsRunning.value) {
            // stop the timer
            appDelegate.notificationDelegate.timerIsRunning.value = false
            self.timer = nil
            self.disposeBag = DisposeBag()
            appDelegate.notificationDelegate.timerValue = 0
            appDelegate.removeNotifications()
            self.picker.isHidden = false
            self.startButton.setTitle("Start timer", for: .normal)
        } else {
            appDelegate.notificationDelegate.timerIsRunning.value = true
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
    }
    
    @objc func tick() {
        print("Do we get called")
        self.appDelegate.notificationDelegate.timerValue -= 1
        self.appDelegate.notificationDelegate.trigger_TimerAllottedUpdate(newtimerValue: self.appDelegate.notificationDelegate.timerValue)
        if (self.appDelegate.notificationDelegate.timerValue <= 0) {
            //sound the alarm
            self.disposeBag = DisposeBag()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.dataSource = self
        self.picker.delegate = self
        self.picker.selectRow(1, inComponent: 0, animated: true)
        self.picker.selectRow(1, inComponent: 1, animated: true)
        appDelegate.notificationDelegate.timerController = self
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        self.checkTimeLeft()
    }
    
    @objc func checkTimeLeft() {
        appDelegate.center.getPendingNotificationRequests(completionHandler: appDelegate.notificationDelegate.gotPendingNotification)
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
