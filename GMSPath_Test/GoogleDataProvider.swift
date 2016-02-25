//
//  GoogleDataProvider.swift
//  Interaction Google StreetView iOS
//
//  Created by Sasa Hu on 2015/7/18.
//  Copyright (c) 2015年 Bo_Cheng. All rights reserved.
//

import UIKit
import GoogleMaps

class GoogleDataProvider: NSObject {
    
    let apiKey = "AIzaSyBzOPMLvFIskPAIxWRAKJGZIUwea5svTtY"
    var session: NSURLSession {
        return NSURLSession.sharedSession()
    }
    
    func parseJsonDataDirection(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: (([GoogleDirectionSteps]?, GoogleDirectionOverview?, NSError?) -> Void)) -> () {
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?key=\(apiKey)&origin=\(from.latitude),\(from.longitude)&destination=\(to.latitude),\(to.longitude)&language=zh-TW&mode=driving"
        let url = NSURL(string: urlString)
        
        var googleStepAll = [GoogleDirectionSteps]()
        let googleDirectionOverview = GoogleDirectionOverview()
        var errorMsg : NSError?
        //let url = NSURL(string: "http://bochengw.twbbs.org/ApiOutput/googleDirectionJson.json")
        
        session.dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            if error != nil {errorMsg = NSError(domain: "Session fetch error", code: 1, userInfo: nil)}
            else {
                
                do {
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
                    
                    if let routes = json["routes"] as AnyObject? as? [AnyObject] {
                        if let bounds = routes.first as? [String: AnyObject] {
                            
                            if let northeast = bounds["northeast"] as AnyObject? as? [String: AnyObject] {
                                if let lat = northeast["lat"] as? CLLocationDegrees {
                                    if let lng = northeast["lng"] as? CLLocationDegrees {
                                        let northeastCoordinate = CLLocationCoordinate2DMake(lat, lng)
                                        
                                        if let southwest = bounds["southwest"] as AnyObject? as? [String: AnyObject] {
                                            if let lat = southwest["lat"] as? CLLocationDegrees {
                                                if let lng = southwest["lng"] as? CLLocationDegrees {
                                                    let southwestCoordinate = CLLocationCoordinate2DMake(lat, lng)
                                                    googleDirectionOverview.bounds = GMSCoordinateBounds(coordinate: northeastCoordinate, coordinate: southwestCoordinate)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if let route = routes.first as? [String: AnyObject] {
                            if let legs = route["legs"] as AnyObject? as? [AnyObject] {
                                if let leg = legs.first as? [String: AnyObject] {
                                    
                                    if let distance = leg["distance"] as? [String: AnyObject] {
                                        if let value = distance["value"] as? Int {
                                            googleDirectionOverview.distance = value
                                        }
                                    }
                                    
                                    if let duration = leg["duration"] as? [String: AnyObject] {
                                        if let value = duration["value"] as? Int {
                                            googleDirectionOverview.duration = value
                                        }
                                    }
                                    
                                    if let end_address = leg["end_address"] as? String {
                                        googleDirectionOverview.end_address = end_address
                                    }
                                    
                                    if let end_location = leg["end_location"] as? [String: AnyObject] {
                                        if let lat = end_location["lat"] as? CLLocationDegrees {
                                            if let lng = end_location["lng"] as? CLLocationDegrees {
                                                googleDirectionOverview.end_location = CLLocationCoordinate2DMake(lat, lng)
                                            }
                                        }
                                    }
                                    
                                    if let start_address = leg["start_address"] as? String {
                                        googleDirectionOverview.start_address = start_address
                                    }
                                    
                                    if let start_location = leg["start_location"] as? [String: AnyObject] {
                                        if let lat = start_location["lat"] as? CLLocationDegrees {
                                            if let lng = start_location["lng"] as? CLLocationDegrees {
                                                googleDirectionOverview.start_location = CLLocationCoordinate2DMake(lat, lng)
                                            }
                                        }
                                    }
                                }
                                
                                if let stepsOverview = legs.first as? [String: AnyObject] {
                                    if let steps = stepsOverview["steps"] as AnyObject? as? [AnyObject] {
                                        for step in steps {
                                            
                                            let googleStep = GoogleDirectionSteps()
                                            if let distance = step["distance"] as AnyObject? as? [String: AnyObject] {
                                                if let value = distance["value"] as? Int {
                                                    googleStep.distance = value
                                                }
                                            }
                                            
                                            if let duration = step["duration"] as AnyObject? as? [String: AnyObject] {
                                                if let value = duration["value"] as? Int {
                                                    googleStep.duration = value
                                                }
                                            }
                                            
                                            if let start_location = step["start_location"] as AnyObject? as? [String: AnyObject] {
                                                if let lat = start_location["lat"] as? CLLocationDegrees {
                                                    if let lng = start_location["lng"] as? CLLocationDegrees {
                                                        googleStep.start_location = CLLocationCoordinate2DMake(lat, lng)
                                                    }
                                                }
                                            }
                                            
                                            if let end_location = step["end_location"] as AnyObject? as? [String: AnyObject] {
                                                if let lat = end_location["lat"] as? CLLocationDegrees {
                                                    if let lng = end_location["lng"] as? CLLocationDegrees {
                                                        googleStep.end_location = CLLocationCoordinate2DMake(lat, lng)
                                                    }
                                                }
                                            }
                                            
                                            if let polyline = step["polyline"] as AnyObject? as? [String: AnyObject] {
                                                if let points = polyline["points"] as? String {
                                                    googleStep.polyline = points
                                                }
                                            }
                                            
                                            if let travel_mode = step["travel_mode"] as? String {
                                                googleStep.travel_mode = travel_mode
                                            }
                                            
                                            if let maneuver = step["maneuver"] as? String {
                                                googleStep.maneuver = maneuver
                                            }
                                            
                                            if let html_instructions = step["html_instructions"] as? String {
                                                googleStep.html_instructions = googleStep.transHtmlInstruciotn(html_instructions)
                                            }
                                            
                                            googleStepAll.append(googleStep)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(googleStepAll, googleDirectionOverview, errorMsg)
                    }
                    
                } catch {
                    errorMsg = NSError(domain: "Fetch Data Error", code: 2, userInfo: nil)
                }
            }
            
        }).resume()
    }
    
    func parseJsonDataAutoCompletion(var searchText: String, withCompletionHandler:(([GoogleAutoCompletions]?, NSError?) -> Void)) -> () {
        var googleAutoCompletion = [GoogleAutoCompletions]()
        var errorMsg: NSError?
        
        searchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        
        let baseUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?"
        let urlString = "\(baseUrl)input=\(searchText)&types=geocode&language=zh-TW&components=country:TW&key=\(apiKey)"
        let placeURL = NSURL(string: urlString)
        
        session.dataTaskWithURL(placeURL!) { (data, response, error) -> Void in
            if error != nil {errorMsg = NSError(domain: "Session error", code: 3, userInfo: nil)}
            else {
                
                do {
                    
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! [String: AnyObject]
                    
                    if let predictions = json["predictions"] as AnyObject? as? [AnyObject] {
                        for prediction in predictions {
                            let autoCompletion = GoogleAutoCompletions()
                            autoCompletion.placeDescription = prediction["description"] as? String
                            autoCompletion.place_id = prediction["place_id"] as? String
                            autoCompletion.reference = prediction["reference"] as? String
                            googleAutoCompletion.append(autoCompletion)
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            withCompletionHandler(googleAutoCompletion, errorMsg)
                        }
                    }

                    
                } catch {
                    errorMsg = NSError(domain: "Fetch Error", code: 4, userInfo: nil)
                }
                    
            }
        }.resume()
        
    }
    
    func fetchPlaceWithId(placeId: String, withCompletionHandler: ((CLLocationCoordinate2D?, String?) -> Void)) -> () {
        let baseUrl = "https://maps.googleapis.com/maps/api/place/details/json?"
        let urlString = "\(baseUrl)placeid=\(placeId)&key=\(apiKey)"
        let place_idUrl = NSURL(string: urlString)
        
        var resultCoordinate: CLLocationCoordinate2D?
        var errorMsg: String?
        
        session.dataTaskWithURL(place_idUrl!) { (data, response, error) -> Void in
            if error != nil {
                errorMsg = "error fetchPlaceWithId"
                print(errorMsg)
            }
            else {
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
                    
                    if let jsonResults = json["result"] as AnyObject? as? [String: AnyObject] {
                        if let geometry = jsonResults["geometry"] as AnyObject? as? [String: AnyObject] {
                            if let location = geometry["location"] as AnyObject? as? [String: AnyObject] {
                                let lat = location["lat"] as! CLLocationDegrees
                                let lng = location["lng"] as! CLLocationDegrees
                                resultCoordinate = CLLocationCoordinate2DMake(lat, lng)
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        withCompletionHandler(resultCoordinate, errorMsg)
                    }
                    
                } catch {
                    errorMsg = "Fetch json error."
                    print(errorMsg)
                }
              
            }
        }.resume()

    }
}
