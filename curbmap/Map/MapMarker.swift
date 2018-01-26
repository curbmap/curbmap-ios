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

class MapMarker: MGLPointAnnotation {
    var heading: CLLocationDirection!
    var color: String!
    var type: AnnotationType!
    var tag: Int!
    var restrictions: [Restriction]!
    var inEffect: Bool!
    var fromLibrary: Bool!
    var identifier: String!
    enum AnnotationType : Int {
        case photo = 0
        case line = 1
        case photoNotDraggable = 2
        case lineNotDraggable = 3
    }
    
    init(coordinate: CLLocationCoordinate2D){
        super.init()
        self.coordinate = coordinate
    }
        
    func get_coordinate() -> CLLocationCoordinate2D {
        return self.coordinate
    }
    
    func set_coordinate(location: CLLocationCoordinate2D) {
        self.coordinate = location
    }
    
    func set_heading(heading: CLLocationDirection) {
        self.heading = heading
    }

    func get_heading() -> CLLocationDirection? {
        return self.heading
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
