//
//  GoogleDirectionSteps.swift
//  Interaction Google StreetView iOS
//
//  Created by Sasa Hu on 2015/7/18.
//  Copyright (c) 2015年 Bo_Cheng. All rights reserved.
//

import UIKit
import GoogleMaps

class GoogleDirectionSteps: NSObject {
    
    var distance: Int?
    
    var duration: Int?
    
    var end_location: CLLocationCoordinate2D?
    
    var html_instructions: String?
    
    var start_location: CLLocationCoordinate2D?
    
    var travel_mode: String?
    
    var maneuver: String?
    
    var polyline: String?
    
    var bounds: GMSCoordinateBounds?
    
    func transHtmlInstruciotn(instrction: String) -> String{
        var result = instrction
        if result != "" {
            while let r = result.rangeOfString("<[^>]+>", options: NSStringCompareOptions.RegularExpressionSearch) {
                result = result.stringByReplacingCharactersInRange(r, withString: "")
            }
        }
        return result
    }
    
    var path: GMSMutablePath?
    
}
