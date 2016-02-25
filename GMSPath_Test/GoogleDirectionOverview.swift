
//
//  GoogleDirectionOverview.swift
//  Interaction Google StreetView iOS
//
//  Created by Huang Ives on 7/18/15.
//  Copyright (c) 2015 Bo_Cheng. All rights reserved.
//

import GoogleMaps

class GoogleDirectionOverview: NSObject {
    
    var bounds: GMSCoordinateBounds?
    
    var copyrights: String?
    
    var distance: Int?
    
    var duration: Int?
    
    var end_address: String?
    
    var end_location: CLLocationCoordinate2D?
    
    var start_address: String?
    
    var start_location: CLLocationCoordinate2D?

}
