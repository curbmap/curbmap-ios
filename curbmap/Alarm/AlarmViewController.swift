//
//  AlarmViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/25/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit

class AlarmViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var menuTableViewController: UITableViewController!

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
            picker.isHidden = false
            startButton.setTitle("Start timer", for: .normal)
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
            picker.isHidden = true
            appDelegate.timer = Timer.scheduledTimer(timeInterval: 1, target: appDelegate, selector: #selector(AppDelegate.tick), userInfo: nil, repeats: false)
            startButton.setTitle("Cancel timer", for: .normal)
        }
        appDelegate.timerIsRunning = !appDelegate.timerIsRunning
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.picker.dataSource = self
        self.picker.delegate = self
        // Do any additional setup after loading the view.
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
