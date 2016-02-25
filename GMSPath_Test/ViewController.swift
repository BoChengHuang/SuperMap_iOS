//
//  ViewController.swift
//  GMSPath_Test
//
//  Created by nrlab on 2015/11/11.
//  Copyright © 2015年 nrlab. All rights reserved.
//

import UIKit
import GoogleMaps
import Socket_IO_Client_Swift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, GMSMapViewDelegate {
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var autoBtn: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let googleDataProvider = GoogleDataProvider()
    let mapModifyMethod = MapModifyMethod()
    var steps = [GoogleDirectionSteps]()
    var overview = GoogleDirectionOverview()
    var candidate = [GoogleAutoCompletions]()
    let mapMethod = MapModifyMethod()
    var timer = NSTimer()
    var autoJump = false

    
    var ntust: CLLocationCoordinate2D = CLLocationCoordinate2DMake(25.0135684, 121.5416816)
    var coordinateList = [CLLocationCoordinate2D]()
    var jumpList = [UInt]()
    
    var camera: GMSCameraPosition!
    var mapView: GMSMapView!
    var marker: GMSMarker!
    var polyline: GMSPolyline?
    var currentState = PositionState()

    let socket = SocketIOClient(socketURL: "127.0.0.1:4000")
    var webConnected = false
    
    @IBAction func nextStep(sender: AnyObject) { jump(1) }
    @IBAction func autoJump(sender: AnyObject) {
        if !autoJump {
            autoJump = true
            self.autoBtn.setTitle("Stop", forState: UIControlState.Normal)
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("jump:"), userInfo: nil, repeats: true)
        } else {
            timer.invalidate()
            self.autoBtn.setTitle("Auto", forState: UIControlState.Normal)
            autoJump = false
        }
    }
    @IBAction func prevJump(sender: AnyObject) { jump(2) }
    func jump(flag: Int) {
        if flag > 2 {
            self.currentState.step++
        } else {
            for var i = 0; i < jumpList.count; i++ {
                if Int(jumpList[i]) > self.currentState.step {
                    if flag == 1 {self.currentState.step = Int(jumpList[i])}
                    if flag == 2 {self.currentState.step = Int(jumpList[i - 2])}
                    break
                }
            }
        }
        
        if self.currentState.step >= self.coordinateList.count - 1 {
            self.showArrivedMessage()
        } else {
            var new_bearing : Double
            self.currentState.coordinate = coordinateList[self.currentState.step]
            new_bearing = mapMethod.getBearing(coordinateList[self.currentState.step], to: coordinateList[self.currentState.step + 1])
            
            if(abs(new_bearing - self.currentState.bearing) > 8){
                self.currentState.bearing = new_bearing
            }
            
            camera = GMSCameraPosition.cameraWithTarget(self.currentState.coordinate, zoom: 16)
            mapView.animateToCameraPosition(camera)
            marker.position = self.currentState.coordinate
            self.updateToStreetView()
            
            let distance = GMSGeometryDistance(self.currentState.coordinate, coordinateList[self.currentState.step - 1])
            print(distance)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.currentState.coordinate = ntust
        self.currentState.bearing = 270
        self.currentState.pitch = 0
        
        camera = GMSCameraPosition(target: ntust, zoom: 16, bearing: 0, viewingAngle: 0)
        mapView = GMSMapView.mapWithFrame(self.view.bounds, camera: camera)
        self.view.insertSubview(mapView, atIndex: 0)
        mapView.myLocationEnabled = true
        print("Init Map")
        
        marker = GMSMarker(position: CLLocationCoordinate2DMake(ntust.latitude, ntust.longitude))
        marker.map = mapView
        
        self.tableView.delegate = self
        self.tableView.hidden = true
        self.searchBar.delegate = self
        self.mapView.delegate = self
        initState()

    }
    
    func initState() {
        socket.on("connect") {data, ack in
            print("socket connected")
            self.webConnected = true
        }
        
        socket.on("latlng", callback: { (data, ack) -> Void in
            var latlng = data.first as! [String: AnyObject]
            self.currentState.coordinate.latitude = latlng["lat"] as! CLLocationDegrees
            self.currentState.coordinate.longitude = latlng["lng"] as! CLLocationDegrees
            
            self.updateMapFromStreetview()
        })
        
        socket.on("pov", callback: { (data, ack) -> Void in
            var pov = data.first as! [String: AnyObject]
            self.currentState.bearing = pov["heading"] as! Double
            self.currentState.pitch = pov["pitch"] as! Double
            
            self.updateMapFromStreetview()
        })
        
        socket.on("links", callback: { (data, ack) -> Void in
            
            self.currentState.links.removeAll(keepCapacity: false)
            let links = data.first as! [AnyObject]
            for link in links {
                let linkElement = GoogleStreetViewLinks()
                linkElement.streetViewDescription = link["description"] as? String
                linkElement.heading = link["heading"] as? Double
                linkElement.pano = link["pano"] as? String
                
                self.currentState.links.append(linkElement)
            }
            
            self.updateMapFromStreetview()
        })
        
        socket.connect()
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.candidate.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        cell.textLabel?.text = self.candidate[indexPath.row].placeDescription!
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        googleDataProvider.fetchPlaceWithId(self.candidate[indexPath.row].place_id!) { (coordinate, error) -> Void in
            self.currentState.destinationCoordinate = coordinate!
            self.getDirection()
            self.tableView.hidden = true
            self.searchBar.endEditing(true)
        }
    }
    
    // MARK: - SearchBar
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        self.tableView.hidden = false
        return true
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        googleDataProvider.parseJsonDataAutoCompletion(searchText) { (results, error) -> Void in
            if error != nil {print(error)}
            else {
                self.candidate = results!
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.tableView.hidden = true
    }
    
    // MARK: - GMSMapView
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {
        self.currentState.coordinate = coordinate
        marker.position = coordinate
        self.updateToStreetView()
    }
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        self.getDirection()
        return true
    }
    
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
    }

    func updateMapFromStreetview() {
        camera = GMSCameraPosition.cameraWithLatitude(self.currentState.coordinate.latitude, longitude: self.currentState.coordinate.longitude, zoom: 16, bearing: self.currentState.bearing, viewingAngle: self.currentState.pitch)
        mapView.animateToCameraPosition(camera)
        marker.position = CLLocationCoordinate2DMake(self.currentState.coordinate.latitude, self.currentState.coordinate.longitude)
    }
    
    func updateToStreetView() {
        let message = ["lat": self.currentState.coordinate.latitude, "lng": self.currentState.coordinate.longitude, "bearing": self.currentState.bearing, "pitch": self.currentState.pitch]
        socket.emit("iOSChange", message)
    }
    
    func getDirection() {
        
        if let destCoordinate = self.currentState.destinationCoordinate {
            googleDataProvider.parseJsonDataDirection(self.currentState.coordinate, to: destCoordinate, completion: { (stepsArray, overviewObject, error) -> Void in
                
                print("Getting Direction...")
                if error != nil {print(error)}
                else {
                    self.coordinateList.removeAll()
                    self.jumpList.removeAll()
                    
                    self.steps = stepsArray!
                    self.overview = overviewObject!
                    
                    self.drawLine()
                    
                    self.nextBtn.hidden = false
                    
                    for step in self.steps {
                        let in_path = GMSMutablePath(fromEncodedPath: step.polyline!)
                        for var i: UInt = 0; i < in_path.count(); i++ { self.coordinateList.append(in_path.coordinateAtIndex(i)) }
                        self.coordinateList = self.mapMethod.refreshCoorList(self.coordinateList)
                        for var j = 0; j < self.coordinateList.count; j++ {
                            if GMSGeometryDistance(step.end_location!, self.coordinateList[j]) < 1 { self.jumpList.append(UInt(j)) }
                        }
                    }
                }
            })
        }
    }
    
    func drawLine() {
        mapView.clear()
        self.marker.position = self.currentState.coordinate
        self.marker.map = self.mapView
        for step in self.steps {
            let polyline = GMSPolyline(path: GMSPath(fromEncodedPath: step.polyline!))
            polyline.strokeWidth = 10
            polyline.map = self.mapView
        }
    }
    
    func showArrivedMessage() {
        self.marker.position = self.coordinateList[self.coordinateList.count - 1]
        
        print("Destination Arrived")
        self.timer.invalidate()
        
        let alert = UIAlertController(title: "Message", message: "You Arrived.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Got It!", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

