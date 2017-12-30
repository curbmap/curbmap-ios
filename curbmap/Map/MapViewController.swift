///Users/eliselkin/Documents/workspace/curbmap/curbmap-ios/curbmap/curbmap.xcodeproj
//  ViewControllerMap.swift
//  curbmap
//
//  Created by Eli Selkin on 7/14/17.
//  Copyright © 2017 curbmap. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import OpenLocationCode
import Mapbox
import SwiftyCam

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var tempGestureRecognizers: [UIGestureRecognizer]!
    var tempViewGestureRecognizers: [UIGestureRecognizer]!
    var menuTableViewController: UITableViewController!
    var photoAnnotation: MapMarker!
    var movingPhotoAnnotation: Bool = false
    var photoToPlace: UIImage!
    var lastTouchPosition:CGPoint!
    var firstTouchPosition:CGPoint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancel(_ sender: Any) {
        self.mapView.removeAnnotation(photoAnnotation)
        self.cancelled()
    }
    @IBOutlet weak var looksGreatButton: UIButton!
    @IBAction func looksGreat(_ sender: Any) {
        if (self.appDelegate.user.get_location() != nil) {
            let olc = try? OpenLocationCode.encode(latitude: self.photoAnnotation.coordinate.latitude, longitude: self.photoAnnotation.coordinate.longitude, codeLength: 12)
            let heading = self.photoAnnotation.heading
            if (olc != nil) {
                let headers = [
                    "Content-Type": "application/x-www-form-urlencoded",
                    "username": self.appDelegate.user.get_username(),
                    "session": self.appDelegate.user.get_session()
                ]
                Alamofire.upload(multipartFormData: { MultipartFormData in
                    MultipartFormData.append(olc!.data(using: String.Encoding.utf8)!, withName: "olc")
                    print(heading)
                    print(heading.magnitude)
                    var heading_magnitude = heading.magnitude
                    MultipartFormData.append(Data(buffer: UnsafeBufferPointer(start: &heading_magnitude, count:1)), withName: "bearing")
                    MultipartFormData.append(UIImageJPEGRepresentation(self.photoToPlace, 1.0)!, withName: "image", fileName: "\(Date().iso8601).jpg", mimeType: "image/jpeg")
                }, usingThreshold:UInt64.init(), to: "https://curbmap.com:50003/imageUpload", method: .post, headers: headers, encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { response in
                            if let result = response.result.value {
                                if let success = result as? NSDictionary {
                                    print(success["success"]! as! Bool)
                                    self.uploadComplete()
                                    return
                                }
                                
                            }
                        }
                        break
                    case .failure(let encodingError):
                        print("failed to send \(encodingError.localizedDescription)")
                        self.navigationController?.popViewController(animated: true)
                        break
                    }
                })
            }
      }
    }
    var zoomLevel: Double = 15.0
    @IBOutlet weak var containerView: UIView!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBAction func menuButton(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
        self.menuTableViewController.tableView.reloadData()
    }
    @IBOutlet weak var searchBar: UISearchBar!
    @IBAction func iconPressed(_ sender: Any) {
        self.trackUser = true
        self.locationManager.startUpdatingLocation()
        self.icon.isHidden = true
    }
    @IBOutlet weak var icon: UIButton!
    
    var mapView: MGLMapView!
    var locationManager: CLLocationManager!
    var coordTouched: CLLocationCoordinate2D!
    var userHeading: CLLocationDirection?
    var longPressGesture: UILongPressGestureRecognizer!
    lazy var geocoder = CLGeocoder()
    var addingLine: Bool = false
    var trackUser: Bool = false
    var offline: Bool = false
    var portrait_oriented: Bool = true
    var mapCache: [String: [ Date: [CurbmapPolyLine]]] = [:]
    let alphabet : [Character] = ["2","3","4","5","6","7","8","9","C","F","G","H","J","M","P","Q","R","V","W","X"]
    // for mapCache [ 10digitcode : [ 2017-07-26@10AM: [lines] ]]]]
    
    func centerMapOnLocation(location: CLLocation) {
        mapView.setCenter(location.coordinate, zoomLevel: self.zoomLevel, animated: true)
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        var code: [Character] = try! OpenLocationCode.encode(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude, codeLength: 10).filter { $0 != "+" }

        let prefix = String(code[0...3])
        let middle = String(code[4...7])
        let suffix = String(code[8...9])
        let currentDate = Date()
        var loadFromCache = [CurbmapPolyLine]()
        let topLeft = self.mapView.convert(CGPoint(x: 20, y: 20), toCoordinateFrom: self.mapView)
        let encodedTopLeft = try? OpenLocationCode(latitude: topLeft.latitude, longitude: topLeft.longitude, codeLength: 10)
        let bottomRight = self.mapView.convert(CGPoint(x: mapView.frame.width-20, y: mapView.frame.height-20), toCoordinateFrom: self.mapView)
        let encodedBottomRight = try? OpenLocationCode(latitude: bottomRight.latitude, longitude: bottomRight.longitude, codeLength: 10)
        var topLeftCodeArray: [Character] = encodedTopLeft!.getCode().filter { $0 != "+" }
        var bottomRightCodeArray: [Character] = encodedBottomRight!.getCode().filter { $0 != "+" }
        var i = 0
        for _ in 0..<topLeftCodeArray.count {
            if (topLeftCodeArray[i] == bottomRightCodeArray[i]) {
                i += 1
                continue
            }
            // X > R or something
            if topLeftCodeArray[i] > bottomRightCodeArray[i] {
                let temp = topLeftCodeArray
                topLeftCodeArray = bottomRightCodeArray
                bottomRightCodeArray = temp
                break
            }
        }
        var codes_to_check : [[Character]] = [topLeftCodeArray, bottomRightCodeArray]
        // Now topLeftCodeArray comes logically before bottomRight
        if (i % 2 == 0 && i != 10){
            // i ended equality on an odd count
            // which means the difference is along both latitude and longitude
            // pos in alphabet for topLeft to bottomRight
            let pos_t_x = alphabet.startIndex.distance(to: alphabet.index(of: topLeftCodeArray[i])!)
            let pos_t_y = alphabet.startIndex.distance(to: alphabet.index(of: topLeftCodeArray[i+1])!)
            let pos_b_x = alphabet.startIndex.distance(to: alphabet.index(of: bottomRightCodeArray[i])!)
            let pos_b_y = alphabet.startIndex.distance(to: alphabet.index(of: bottomRightCodeArray[i+1])!)
            
            for x in stride(from: pos_t_x, to: pos_b_x, by: 2) {
                for y in stride(from: pos_t_y, to: pos_b_y, by: 2){
                    print(x, y)
                }
            }
        }
    }
    func getNewDataForRegion(code: [Character]) {
        var codePlus = code
        codePlus.insert("+", at: 8)
        print(String(codePlus))
        let codeArea = try? OpenLocationCode.decode(code: String(codePlus))
        let headers = [
            "session": appDelegate.user.get_session(),
            "username": appDelegate.user.get_username()
        ]
        let parameters = [
            "lat1": (codeArea?.latitudeHigh)!,
            "lng1": (codeArea?.longitudeHigh)!,
            "lat2": (codeArea?.latitudeLow)!,
            "lng2": (codeArea?.longitudeLow)!
        ]
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
       self.searchBarSearchButtonClicked(searchBar)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //geocoder.cancelGeocode()
        print("HERE XXX IN GEOCODE")
        geocoder.geocodeAddressString((searchBar.text)!, completionHandler: { (placemarks, error) in
            // Process Response
            print((searchBar.text)!)
            self.processGeocode(withPlacemarks: placemarks, error: error)
        })
        self.searchBar.endEditing(true)
    }
    
    func processGeocode(withPlacemarks : [CLPlacemark]?, error: Error?) {
        if (error != nil) {
            print(error.debugDescription)
            return
        }
        if ((withPlacemarks?.count)! > 0) {
            let point: CLLocationCoordinate2D = (withPlacemarks?[0].location?.coordinate)!
            centerMapOnLocation( location: CLLocation(latitude: point.latitude, longitude: point.longitude) )
        }
    }
    @objc func changeStyle(style: String) {
        var url: URL
        if (style == "d") {
            url = URL(string: "mapbox://styles/mapbox/dark-v9")!
        } else {
            url = URL(string: "mapbox://styles/mapbox/streets-v10")!
        }
        self.mapView.styleURL = url
        self.mapView.reloadStyle(self)
    }
    
    @objc func changeOffline(offline: String) {
        if (offline == "y") {
            self.offline = true
        } else {
            self.offline = false
        }
    }
    @objc func changeUnits(units: String) {
        if (units == "mi") {
            // we don't return anything in units yet
        } else {
            // we don't have a member variable for this
        }
    }
    
    @objc func setupMap() {
        let url = URL(string: "mapbox://styles/mapbox/dark-v9")!
        self.mapView = MGLMapView(frame: view.bounds, styleURL: url)
        self.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView.delegate = self;
        self.mapView.setUserTrackingMode(MGLUserTrackingMode.follow, animated: true)
        self.mapView.showsHeading = true
        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(determineLongPressAction))
        self.mapView.addGestureRecognizer(self.longPressGesture)
        view.insertSubview(self.mapView, at: 0)
        self.appDelegate.mapController = self        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMap()
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingHeading()
        self.locationManager.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        let pan: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userPanned))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.searchBar.delegate = self
        setupViews(portrait_oriented)
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func userPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.ended) {
            self.trackUser = false
            self.icon.isHidden = false
            // display something so they can turn it back on
        }
    }
    
    @objc func determineLongPressAction(gestureRecognizer:UIGestureRecognizer) {
        let touched = gestureRecognizer.location(in: self.mapView)
        self.coordTouched = mapView.convert(touched, toCoordinateFrom: self.mapView)
        if (self.addingLine) {
            // put another point on the map
        } else {
            // determine if user wants to add a line or a photo
            // 3d touch?
            let alertController = UIAlertController(title: "Line or Photo", message:
                "Would you like to draw a line or a photo?", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Line", style: .default, handler: handleAlert))
            alertController.addAction(UIAlertAction(title: "Photo", style: .default, handler: handleAlert))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    @objc func handleAlert(action: UIAlertAction) {
        if (action.title == "Line") {
            self.addingLine = true
            // handle putting the first point on the map with the coordinate in memory self.coordTouched
        } else {
            //create photo view controller and push onto navigation
            self.trackUser = false
            self.appDelegate.user.set_location(location: locationManager.location!)
            let vc = PhotoController(nibName: "PhotoController", bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    func setupViews(_ portrait: Bool) {
        var displaywidth = Int((view.frame.width))
        var displayheight = Int((view.frame.height))
        if ((!portrait && displaywidth < displayheight) || (portrait && displayheight < displaywidth)) {
            displaywidth = Int((view.frame.height))
            displayheight = Int((view.frame.width))
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (_) in
            let orient = UIApplication.shared.statusBarOrientation
            self.portrait_oriented = orient.isPortrait
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.setupViews(self.portrait_oriented)
        })
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        //contentInset.bottom = keyboardFrame.size.height
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    @objc func dismissKeyboard() {
        searchBar.endEditing(true)
        self.containerView.isHidden = true
        menuOpen = false
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        var contentInset:UIEdgeInsets = UIEdgeInsets.zero
        contentInset.top = contentInset.top + 44 + 20
        setupViews(self.portrait_oriented)
    }
    
    @objc func uploadComplete() {
        print("completed upload!")
        self.cancelled()
    }
    @objc func cancelled() {
        self.cancelButton.isHidden = true
        self.looksGreatButton.isHidden = true
        self.zoomLevel = 15.0
        if (self.appDelegate.user.settings["follow"] == "y"){
            self.trackUser = true
        }
        self.mapView.gestureRecognizers = self.tempGestureRecognizers
        self.view.gestureRecognizers = []
        for listedGestureRecognizer in tempViewGestureRecognizers {
            if (listedGestureRecognizer.isKind(of: UIPanGestureRecognizer.self)) {
                let gestureToAdd: UIPanGestureRecognizer = listedGestureRecognizer as! UIPanGestureRecognizer
                self.view.addGestureRecognizer(gestureToAdd)
            }
            else if (listedGestureRecognizer.isKind(of: UILongPressGestureRecognizer.self)) {
                let gestureToAdd: UILongPressGestureRecognizer = listedGestureRecognizer as! UILongPressGestureRecognizer
                self.view.addGestureRecognizer(gestureToAdd)
            } else if (listedGestureRecognizer.isKind(of: UITapGestureRecognizer.self)) {
                let gestureToAdd: UITapGestureRecognizer = listedGestureRecognizer as! UITapGestureRecognizer
                self.view.addGestureRecognizer(gestureToAdd)
                
            }
        }
        self.movingPhotoAnnotation = false
        self.photoToPlace = nil
        self.photoAnnotation = nil
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                    self.locationManager.startUpdatingLocation()
                    self.locationManager.startUpdatingHeading()
                    self.centerMapOnLocation(location: self.locationManager.location!)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latest:CLLocation = locations[locations.count - 1]
        if (self.trackUser) {
            self.appDelegate.user.set_location(location: latest)
            self.centerMapOnLocation(location: latest)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 { return }
        self.userHeading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        self.appDelegate.user.set_location(location: manager.location!)
    }
    @objc func movePhotoMarker(_ photoMoved: UITapGestureRecognizer) {
        // point teleportation!
        let lastMovedTo = photoMoved.location(in: self.mapView)
        let photoAnnotationLocation = mapView.convert(lastMovedTo, toCoordinateFrom: self.mapView)
        self.mapView.removeAnnotation(photoAnnotation)
        self.photoAnnotation.coordinate = photoAnnotationLocation
        self.mapView.addAnnotation(photoAnnotation)
    }
    @objc func moveMap(_ mapMoved: UIPanGestureRecognizer) {
        if (mapMoved.state == .began) {
            self.firstTouchPosition = mapMoved.location(in: self.mapView)
        }
        if (mapMoved.state == .ended) {
            self.lastTouchPosition = mapMoved.location(in: self.mapView)
            let origin = self.mapView.convert(self.firstTouchPosition, toCoordinateFrom: self.mapView)
            let ending = self.mapView.convert(self.lastTouchPosition, toCoordinateFrom: self.mapView)
            var center = self.mapView.centerCoordinate
            let dist_lng = origin.longitude - ending.longitude
            let dist_lat = origin.latitude - ending.latitude
            center.longitude += dist_lng
            center.latitude += dist_lat
            let center_location = CLLocation(latitude: center.latitude, longitude: center.longitude)
            self.centerMapOnLocation(location: center_location)
        }
    }
    
    @objc func placePhoto() {
        // Display mapmarker
        // on mapMarker show little photo?
        // Then turn off dragging of map and add a pan gesture which moves the marker only
        self.zoomLevel = 17
        centerMapOnLocation(location: self.appDelegate.user.get_location()!)
        if (self.userHeading != nil) {
            self.photoAnnotation = MapMarker(coordinate: self.appDelegate.user.get_location()!.coordinate, heading: self.userHeading!)
        } else {
            self.photoAnnotation = MapMarker(coordinate: self.appDelegate.user.get_location()!.coordinate)
        }
        self.movingPhotoAnnotation = true
        self.mapView.addAnnotation(self.photoAnnotation)
        self.tempGestureRecognizers = self.mapView.gestureRecognizers! // copy the gesture recognizers to replace later
        self.mapView.gestureRecognizers = []
        self.tempViewGestureRecognizers = self.view.gestureRecognizers!
        let tapGestureMarker = UITapGestureRecognizer(target: self, action: #selector(movePhotoMarker))
        tapGestureMarker.delegate = self
        let panGestureMarker = UIPanGestureRecognizer(target: self, action: #selector(moveMap))
        panGestureMarker.delegate = self
        self.view.gestureRecognizers = [panGestureMarker, tapGestureMarker]
        self.looksGreatButton.isHidden = false
        self.cancelButton.isHidden = false
        self.icon.isHidden = true
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UITableViewController,
            segue.identifier == "ShowMenuFromMap" {
            self.menuTableViewController = vc
        }
    }
}


