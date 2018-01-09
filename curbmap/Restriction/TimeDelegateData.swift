//
//  TimeDelegate.swift
//  curbmap
//
//  Created by Eli Selkin on 1/8/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import Foundation
import UIKit

class TimeDelegateData: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            return 24
        } else {
            return 60
        }
    }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let keyValue = [NSAttributedStringKey.foregroundColor: UIColor.white]
        let str = NSAttributedString(string: String(row), attributes: keyValue)
        return str
    }
}
