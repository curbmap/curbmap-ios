//
//  PolyLine.swift
//  curbmap
//
//  Created by Eli Selkin on 7/14/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import Foundation
import MapKit
import Mapbox
class CurbmapPolyLine: MGLPolylineFeature {
    var color: UIColor?
    var restrictions: [Restriction] = []
    var inEffect: Bool?    
}

