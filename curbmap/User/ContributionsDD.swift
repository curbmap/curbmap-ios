//
//  ContributionsDD.swift
//  curbmap
//
//  Created by Eli Selkin on 1/13/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation
import UIKit

class ContributionsDD: NSObject, UITableViewDelegate, UITableViewDataSource {
    var contributionsPhotos: [PhotoContributions] = []
    var contributionsLines: [LineContributions] = []
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contributionsPhotos.count + contributionsLines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ContributionCell") as? ContributionCell
        if cell == nil {
          cell = ContributionCell(style: .default, reuseIdentifier: "ContributionCell")
        }
        
        if indexPath.row < contributionsPhotos.count {
            cell?.locationLabel.text = "[\(contributionsPhotos[indexPath.row].coordinate.longitude),\(contributionsPhotos[indexPath.row].coordinate.latitude)]"
            cell?.dateLabel.text = "on: \(contributionsPhotos[indexPath.row])"
            cell?.typeImage.image = UIImage(named: "photomarker")
        } else {
            let pos = indexPath.row - contributionsPhotos.count
            cell?.locationLabel.text = "[\(contributionsLines[pos].coordinate.longitude),\(contributionsLines[pos].coordinate.latitude)]"
            cell?.dateLabel.text = "on: \(contributionsLines[pos])"
            cell?.typeImage.image = UIImage(named: "linemarker")
        }
        return cell!
    }
    
}

class PhotoContributions {
    var coordinate: CLLocationCoordinate2D!
    var date: Date!
}

class LineContributions {
    var coordinate: CLLocationCoordinate2D!
    var date: Date!
}
