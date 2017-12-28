//
//  MapMarker.swift
//  curbmap
//
//  Created by Eli Selkin on 7/14/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import Foundation
import MapKit
import Mapbox

class MapMarker: NSObject, MGLAnnotation {
    var coordinate: CLLocationCoordinate2D
    var color: String!
    var restrictions: [Restriction]!
    var inEffect: Bool!
    init(coordinate: CLLocationCoordinate2D){
        self.coordinate = coordinate
    }
}
