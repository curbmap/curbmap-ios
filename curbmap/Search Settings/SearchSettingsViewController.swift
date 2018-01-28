//
//  SearchSettingsViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 1/15/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import UIKit

class SearchSettingsViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBAction func backPushed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func savePushed(_ sender: Any) {
        self.appDelegate.saveSearchSettings(limit: self.timeLimitField.text!, distance: self.timeLimitField.text!, date: self.timePicker.calendar.dateComponents([.minute, .hour, .day, .month, .year, .weekday], from: self.timePicker.date))
        self.navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var timeLimitField: UITextField!
    @IBAction func timeLimitFieldChanged(_ sender: Any) {
        var value = Int(timeLimitField.text!)!
        if (value < 15) {
            value = 15
        }
        self.timeLimitField.text = String(value)
    }
    
    
    @IBOutlet weak var distanceLimitField: UITextField!
    
    @IBAction func distanceLimitFieldChanged(_ sender: Any) {
        var value = Float(distanceLimitField.text!)!
        if (value < 0.1) {
            value = 0.1
        }
        self.distanceLimitField.text = String(format: "%03.2f", value)
    }
    @IBOutlet weak var distanceUnit: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBAction func timePickerChanged(_ sender: Any) {
    }

    func getNext(_ weekday: Int, _ hour: Int, _ minute: Int, considerToday consider: Bool = true) -> Date {
        let calendar = Calendar.current
        var yesterday: Date!
        if (consider) {
            yesterday = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date())
        } else {
            yesterday = Date()
        }
        let following = calendar.nextDate(after: yesterday!, matching: DateComponents(hour: hour, minute: minute, weekday: weekday), matchingPolicy: .nextTime)
        return following!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.timePicker.setValue(UIColor.white, forKey: "textColor")
        if (appDelegate.user.settings["units"] == "km") {
            self.distanceUnit.text = "km"
        } else {
            self.distanceUnit.text = "mi"
        }
        if (self.appDelegate.user.searchSettings["weekday"]! as! Int != 0 || self.appDelegate.user.searchSettings["hour"]! as! Int != 0 || self.appDelegate.user.searchSettings["minute"]! as! Int != 0) {
            let weekday = self.appDelegate.user.searchSettings["weekday"] as! Int
            let hour = self.appDelegate.user.searchSettings["hour"] as! Int
            let minute = self.appDelegate.user.searchSettings["minute"] as! Int
            let nextDate = getNext(weekday, hour, minute, considerToday: true)
            self.timePicker.setDate(nextDate, animated: true)
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
