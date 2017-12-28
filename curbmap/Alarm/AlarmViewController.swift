//
//  AlarmViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import EventKit

class AlarmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var menuTableViewController: UITableViewController!
    
    var eventStore: EKEventStore!
    var reminders: [EKReminder]!
    var reminder: EKReminder!
    
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
        if (appDelegate.timerIsRunning) {
            // stop the timer
            for reminder in reminders {
                if (reminder.title == "get car") {
                    reminder.isCompleted = true
                    reminder.completionDate = Date()
                    do {
                        try eventStore.remove(reminder, commit: true)
                        picker.isHidden = false
                        timerLabel.isHidden = true
                        startButton.setTitle("Start timer", for: .normal)
                        appDelegate.timer = nil
                        appDelegate.timerAlloted = 0
                    } catch {
                        print("Error removing reminder!")
                    }
                }
            }
            
        } else {
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
            appDelegate.timerAlloted = Int64(hours * (60*60) + minutes * 60)
            print("Alloted: ", appDelegate.timerAlloted)
            let futureDate = Date().addingTimeInterval(TimeInterval(appDelegate.timerAlloted))
            let reminderToSet = EKReminder(eventStore: self.eventStore)
            reminderToSet.title = "get car"
            let calendarUnit: Set<Calendar.Component> = [.hour, .day, .month, .year]
            let dateComponents = Calendar.current.dateComponents(calendarUnit, from: futureDate)
            print("dateComponents:", dateComponents)
            reminderToSet.dueDateComponents = dateComponents
            reminderToSet.addAlarm(EKAlarm(absoluteDate: futureDate))
            
            reminderToSet.calendar = self.eventStore.defaultCalendarForNewReminders()
            do {
                try self.eventStore.save(reminderToSet, commit: true)
                dismiss(animated: true, completion: nil)
            }catch{
                print("Error creating and saving new reminder : \(error)")
            }
            picker.isHidden = true
            timerLabel.isHidden = false
            setRemainingTime(appDelegate.timerAlloted)
            if (appDelegate.timer == nil) {
                appDelegate.timer = Timer.scheduledTimer(timeInterval: 1, target: appDelegate, selector: #selector(AppDelegate.tick), userInfo: nil, repeats: true)
            }
            startButton.setTitle("Cancel timer", for: .normal)
        }
        appDelegate.timerIsRunning = !appDelegate.timerIsRunning
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.dataSource = self
        self.picker.delegate = self
        self.picker.selectRow(1, inComponent: 0, animated: true)
        self.picker.selectRow(1, inComponent: 1, animated: true)
        appDelegate.timerController = self
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        self.eventStore = EKEventStore()
        self.reminders = [EKReminder]()
        self.eventStore.requestAccess(to: EKEntityType.reminder, completion: { (granted: Bool, error: Error?) in
            if granted{
                // 2
                let predicate = self.eventStore.predicateForReminders(in: nil)
                self.eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
                    
                    self.reminders = reminders
                    DispatchQueue.main.async {
                        self.checkTimeLeft()
                    }
                })
            }else{
                print("The app is not permitted to access reminders, make sure to grant permission in the settings and try again")
            }
            })
    }
    
    @objc func checkTimeLeft() {
        for reminder in reminders {
            if (reminder.title == "get car") {
                let calendar = Calendar.current
                let startDate = Date()
                print("Start:", startDate)
                let endDate = (reminder.dueDateComponents?.date)!
                print("End:", endDate)
                if (startDate < endDate) {
                    let dateComponents = calendar.dateComponents(Set<Calendar.Component>([ .second]), from: startDate, to: endDate)
                    self.appDelegate.timerAlloted = Int64((dateComponents.second)!)
                    if (self.appDelegate.timer == nil) {
                        appDelegate.timer = Timer.scheduledTimer(timeInterval: 1, target: appDelegate, selector: #selector(AppDelegate.tick), userInfo: nil, repeats: true)
                    }
                    self.setRemainingTime(Int64(dateComponents.second!))
                } else {
                    appDelegate.timer = nil
                    appDelegate.timerIsRunning = false
                    appDelegate.timerAlloted = 0
                    self.setRemainingTime(0)
                }
            }
        }
    }
    
    @objc func setRemainingTime(_ timeRemaining: Int64) {
        let hours = Int(floor(Double(timeRemaining) / (60.0*60.0)))
        let minutes = Int(floor((Double(timeRemaining) - (Double(hours) * (60.0*60.0))) / 60.0))
        let seconds = Int(floor(Double(timeRemaining) - (Double(hours) * 60.0*60.0) - (Double(minutes) * 60.0)))
        timerLabel.text = String(format:"%02d : %02d : %02d", hours, minutes, seconds)
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
