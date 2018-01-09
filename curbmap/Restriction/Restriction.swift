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
    var timeLimit: Int?
    var permit: String?
    var cost: Float?
    var per: Int?
    var isNew: Bool = true
    var isEdited: Bool = false
    var dateAdded: Date?
    var id: String = ""
    var creator_score: Int = 0
    var angle: Int = 0
    init(type: Int, days: [Bool], weeks: [Bool], months: [Bool], from: Int, to: Int, angle: Int, limit: Int?, cost: Float?, per: Int?, permit: String?){
        if let costFloat = cost {
            self.cost = costFloat
        }
        if let perInt = per {
            self.per = perInt
        }
        if let permitString = permit {
            self.permit = permitString
        }
        self.angle = angle
        self.type = type
        self.days = days
        self.weeks = weeks
        self.months = months
        self.fromTime = from
        self.toTime = to
        self.timeLimit = limit
    }
    var description: String  {
        let format = "{'type': '%@', 'days': %@, 'weeks': %@, 'months': %@, 'fromTime': %d, 'toTime': %d, 'angle': %d, 'limit': %d, 'permit': '%@', 'cost': %4.2f, 'per': %d, 'id': '%@', 'creator_score': %d}"
        let daysJSON = JSONStringify(value: days as AnyObject, prettyPrinted: false)
        let monthsJSON = JSONStringify(value: months as AnyObject, prettyPrinted: false)
        let weeksJSON = JSONStringify(value: weeks as AnyObject, prettyPrinted: false)
        return String(format: format, type, daysJSON, weeksJSON, monthsJSON, fromTime, toTime, angle, timeLimit != nil ? timeLimit! : 0, permit != nil ? permit! : "", cost != nil ? cost! : 0.0, per != nil ? per! : 0, id, creator_score)
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
