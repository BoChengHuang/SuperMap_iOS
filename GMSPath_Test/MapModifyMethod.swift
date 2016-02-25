//
//  MapModifyMethod.swift
//  Interaction Google StreetView iOS
//
//  Created by nrlab on 2015/8/20.
//  Copyright (c) 2015年 nrlab. All rights reserved.
//

import Foundation
import GoogleMaps

class MapModifyMethod: NSObject {
    
    func degreesToRadians(degree: Double) -> Double {
        return (M_PI * degree / 180.0)
    }
    
    func radiandsToDegrees(rad: Double) -> Double {
        return (rad * 180.0 / M_PI)
    }
    
    func getBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDirection {
        var bearing: CLLocationDirection!
        let fLat = self.degreesToRadians(from.latitude)
        let fLng = self.degreesToRadians(from.longitude)
        let tLat = self.degreesToRadians(to.latitude)
        let tLng = self.degreesToRadians(to.longitude)
        let degree: Double = self.radiandsToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)))
        if (degree >= 0) {
            bearing = degree
        } else {
            bearing = 360 + degree
        }
        
        return bearing
    }
    
    func findMinBearing(links: [GoogleStreetViewLinks]!, bearing: CLLocationDirection) -> CLLocationDirection {
        var min_different_bearing: CLLocationDirection = 360
        var min_Bearing: CLLocationDirection = 0
        for link in links {
            let different_bearing = abs(bearing - link.heading!)
            if different_bearing < min_different_bearing {
                min_different_bearing = different_bearing
                min_Bearing = link.heading!
            }
        }
        return min_Bearing
    }
    
    func refreshCoorList(old_coodList: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var coodList = old_coodList
        let threshold: CLLocationDistance = 5
        var step = 0
        while step < coodList.count - 1 {
            let distance = GMSGeometryDistance(coodList[step + 1], coodList[step])
            let n = Int(distance / threshold)
            if distance > threshold {
                let det_lat = (coodList[step + 1].latitude - coodList[step].latitude) / CLLocationDegrees(n)
                let det_lng = (coodList[step + 1].longitude - coodList[step].longitude) / CLLocationDegrees(n)
                
                for var j = 0; j < n; j++ {
                    coodList.insert(CLLocationCoordinate2DMake(coodList[step + j].latitude + det_lat, coodList[step + j].longitude + det_lng), atIndex: step + j + 1)
                }
            }
            coodList.removeAtIndex(step + n)
            step += n
        }
        return coodList
    }
}
