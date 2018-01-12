//
//  Restriction.swift
//  curbmap
//
//  Created by Eli Selkin on 7/14/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import Foundation

class Restriction : CustomStringConvertible {
    var type: Int = 0
    var days: [Bool] = [false, false, false, false, false, false, false]
    var weeks: [Bool] = [true, true, true, true]
    var months: [Bool] = [true, true, true, true, true, true, true, true, true, true, true, true]
    var fromTime: Int = 0
    var toTime: Int = 0
    var enforcedHolidays: Bool = true
    var vehicleType: Int = 0
    var timeLimit: Int?
    var permit: String?
    var cost: Float?
    var per: Int?
    var side: Int = 0
    var isNew: Bool = true
    var isEdited: Bool = false
    var dateAdded: Date?
    var id: String = ""
    var creator_score: Int = 0
    var angle: Int = 0
    init(type: Int, days: [Bool], weeks: [Bool], months: [Bool], from: Int, to: Int, angle: Int, holidays: Bool, vehicle: Int, side: Int, limit: Int?, cost: Float?, per: Int?, permit: String?){
        self.cost = cost
        self.per = per
        self.permit = permit
        self.angle = angle
        self.type = type
        self.days = days
        self.weeks = weeks
        self.months = months
        self.fromTime = from
        self.side = side
        self.enforcedHolidays = holidays
        self.vehicleType = vehicle
        self.toTime = to
        self.timeLimit = limit
    }
    var description: String  {
        let format = "{\"type\": %d, \"days\": %@, \"weeks\": %@, \"months\": %@, \"start\": %d, \"end\": %d, \"angle\": %d, \"side\": %d, \"duration\": %@, \"vehicle\": %@, \"permit\": %@, \"cost\": %@, \"per\": %@, \"holiday\": %@}"
        let daysJSON = JSONStringify(value: days as AnyObject, prettyPrinted: false)
        let monthsJSON = JSONStringify(value: months as AnyObject, prettyPrinted: false)
        let weeksJSON = JSONStringify(value: weeks as AnyObject, prettyPrinted: false)
        return String(format: format, type, daysJSON, weeksJSON, monthsJSON, fromTime, toTime, angle, side, timeLimit != nil ? String(timeLimit!) : "null", String(vehicleType), permit != nil ? "\""+permit!+"\"" : "null", cost != nil ? String(format: "%4.2f", cost!) : "null", per != nil ? String(per!) : "null", enforcedHolidays.description)
    }
    
    var debugDescription: String {
        return self.description
    }
    
    // https://gist.github.com/santoshrajan/97aa46871cde0c0cb8a8
    func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value) {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            }
        }
        return ""
    }
}
extension Restriction {
    func asDictionary() -> [String: Any] {
        return [
            "type": type,
            "days": days,
            "weeks": weeks,
            "months": months,
            "start": fromTime,
            "end": toTime,
            "angle": angle,
            "side": side,
            "duration": timeLimit ?? nil,
            "vehicle": vehicleType,
            "permit": permit ?? nil,
            "cost": cost ?? nil,
            "per": per ?? nil,
            "holiday": enforcedHolidays
        ]
    }
}
