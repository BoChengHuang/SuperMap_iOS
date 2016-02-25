//
//  PositionState.swift
//  Interaction Google StreetView iOS
//
//  Created by nrlab on 2015/8/20.
//  Copyright (c) 2015年 nrlab. All rights reserved.
//

import Foundation
import GoogleMaps

class PositionState: NSObject {
    
    var coordinate: CLLocationCoordinate2D!
    
    var bearing: CLLocationDirection!
    
    var pitch: CLLocationDegrees!
    
    var destinationCoordinate: CLLocationCoordinate2D?
    
    var links = [GoogleStreetViewLinks]()
    
    var step = 0
}
