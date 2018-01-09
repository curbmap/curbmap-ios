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
import Instructions
import SnapKit
import Photos
import AVFoundation
import RxCocoa

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, CoachMarksControllerDataSource, CoachMarksControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let coachMarksController = CoachMarksController()
    let coachMarkSkip = CoachMarkSkipDefaultView()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var tempGestureRecognizers: [UIGestureRecognizer]!
    var tempViewGestureRecognizers: [UIGestureRecognizer]!
    var menuTableViewController: UITableViewController!
    var photoAnnotation: MapMarker!
    var polyline: CurbmapPolyLine!
    var movingPhotoAnnotation: Bool = false
    var photoToPlace: UIImage!
    var photoToPlaceHeading: CLHeading!
    var photoToPlaceLocation: CLLocation!
    var lastTouchPosition:CGPoint!
    var firstTouchPosition:CGPoint!
    var line: [MapMarker] = []
    var picker: UIImagePickerController!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var lineCancelButton: UIButton!
    
    @IBAction func cancel(_ sender: Any) {
        self.mapView.removeAnnotation(photoAnnotation)
        self.cancelled()
    }
    @IBAction func cancelLine(_ sender: Any) {
        self.mapView.removeAnnotations(self.line)
        self.mapView.remove(self.polyline)
        self.lineCancelled()
    }
    @IBOutlet weak var looksGreatButton: UIButton!
    @IBOutlet weak var lineLooksGreatButton: UIButton!
    @IBAction func looksGreat(_ sender: Any) {
        self.looksGreatButton.isEnabled = false
        if (self.photoAnnotation != nil) {
            print("working photo annotation")
            let olc = try? OpenLocationCode.encode(latitude: self.photoAnnotation.coordinate.latitude, longitude: self.photoAnnotation.coordinate.longitude, codeLength: 12)
            let heading = self.photoAnnotation.heading
            if (olc != nil) {
                let headers = [
                    "Content-Type": "application/x-www-form-urlencoded",
                    "username": self.appDelegate.user.get_username(),
                    "session": self.appDelegate.user.get_session()
                ]
                let imageData = UIImageJPEGRepresentation(self.photoToPlace, 1.0)!
                let cgImgSource = CGImageSourceCreateWithData(imageData as CFData, nil)!
                let uti:CFString = CGImageSourceGetType(cgImgSource)!
                let dataWithEXIF: NSMutableData = NSMutableData(data: imageData)
                let destination: CGImageDestination = CGImageDestinationCreateWithData((dataWithEXIF as CFMutableData), uti, 1, nil)!
                
                let imageProperties = CGImageSourceCopyPropertiesAtIndex(cgImgSource, 0, nil)! as NSDictionary
                let mutable: NSMutableDictionary = imageProperties.mutableCopy() as! NSMutableDictionary
                let EXIFDictionary: NSMutableDictionary = (mutable[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary)!
                let GPSDictionary: NSMutableDictionary = NSMutableDictionary()
                GPSDictionary.setValue(NSNumber(floatLiteral: fabs(self.photoAnnotation.coordinate.latitude)), forKey: kCGImagePropertyGPSLatitude as String)
                GPSDictionary.setValue(NSNumber(floatLiteral: fabs(self.photoAnnotation.coordinate.latitude)), forKey: kCGImagePropertyGPSLatitude as String)
                GPSDictionary.setValue(NSNumber(floatLiteral: fabs(self.photoAnnotation.coordinate.latitude)), forKey: kCGImagePropertyGPSDestLatitude as String)
                if (self.photoAnnotation.coordinate.latitude > 0) {
                    GPSDictionary.setValue( "N", forKey: kCGImagePropertyGPSLatitudeRef as String)
                    GPSDictionary.setValue( "N", forKey: kCGImagePropertyGPSDestLatitudeRef as String)
                    // north
                } else {
                    // south
                    GPSDictionary.setValue( "S", forKey: kCGImagePropertyGPSLatitudeRef as String)
                    GPSDictionary.setValue( "S", forKey: kCGImagePropertyGPSDestLatitudeRef as String)
                }
                GPSDictionary.setValue( NSNumber(floatLiteral: fabs(self.photoAnnotation.coordinate.longitude)), forKey: kCGImagePropertyGPSLongitude as String)
                GPSDictionary.setValue( NSNumber(floatLiteral: fabs(self.photoAnnotation.coordinate.longitude)), forKey: kCGImagePropertyGPSDestLongitude as String)
                if (self.photoAnnotation.coordinate.longitude < 0) {
                    // W
                    GPSDictionary.setValue( "W", forKey: kCGImagePropertyGPSLongitudeRef as String)
                    GPSDictionary.setValue( "W", forKey: kCGImagePropertyGPSDestLongitudeRef as String)
                } else {
                    // E
                    GPSDictionary.setValue( "E", forKey: kCGImagePropertyGPSLongitudeRef as String)
                    GPSDictionary.setValue( "E", forKey: kCGImagePropertyGPSDestLongitudeRef as String)
                }
                GPSDictionary.setValue(NSNumber(floatLiteral: self.photoAnnotation.heading.magnitude), forKey: kCGImagePropertyGPSDestBearing as String)
                GPSDictionary.setValue("N", forKey: kCGImagePropertyGPSDestBearingRef as String)
                mutable.setValue(EXIFDictionary, forKey: kCGImagePropertyExifDictionary as String)
                mutable.setValue(GPSDictionary, forKey: kCGImagePropertyGPSDictionary as String)
                CGImageDestinationAddImageFromSource(destination, cgImgSource, 0, (mutable as CFDictionary))
                CGImageDestinationFinalize(destination)

                if (NetworkReachabilityManager()?.isReachableOnEthernetOrWiFi)! {
                    let annotation = self.photoAnnotation!
                    DispatchQueue.global(qos: .background).async {
                        let localDataWithExif = (dataWithEXIF as Data)
                        let localCoord = annotation.coordinate
                        let localHeading = annotation.heading!
                        Alamofire.upload(multipartFormData: { MultipartFormData in
                            MultipartFormData.append(olc!.data(using: String.Encoding.utf8)!, withName: "olc")
                            if let heading_magnitude = heading?.magnitude {
                                MultipartFormData.append("\(heading_magnitude)".data(using: String.Encoding.utf8)!, withName: "bearing")
                            }
                            MultipartFormData.append(dataWithEXIF as Data, withName: "image", fileName: "\(Date().iso8601).jpg", mimeType: "image/jpeg")
                        }, usingThreshold:UInt64.init(), to: "https://curbmap.com:50003/imageUpload", method: .post, headers: headers, encodingCompletion: { encodingResult in
                            switch encodingResult {
                            case .success(let upload, _, _):
                                upload.responseJSON { response in
                                    if let result = response.result.value {
                                        if let success = result as? NSDictionary {
                                            print(success["success"]! as! Bool)
                                            PHPhotoLibrary.shared().save(imageData: localDataWithExif, location: localCoord, heading: localHeading, appDelegate: self.appDelegate, completed: true)
                                            return
                                        }
                                        
                                    }
                                }
                                break
                            case .failure(let encodingError):
                                print("failed to send \(encodingError.localizedDescription)")
                                PHPhotoLibrary.shared().save(imageData: dataWithEXIF as Data, location: self.photoAnnotation.coordinate, heading: self.photoAnnotation.heading, appDelegate: self.appDelegate, completed: false)
                            }
                        })
                    }
                    self.cancelled()
                    } else {
                        PHPhotoLibrary.shared().save(imageData: dataWithEXIF as Data, location: self.photoAnnotation.coordinate, heading: self.photoAnnotation.heading, appDelegate: self.appDelegate, completed: false)
                        self.cancelled()
                    }
                }
        }
    }
    @IBAction func lineLooksGreat(_ sender: Any) {
        let vc = RestrictionViewController(nibName: "Restriction", bundle: nil)
        vc.setCancel(function: self.cancelLine)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBOutlet weak var centerBox: UIView!
    var zoomLevel: Double = 15.0
    @IBOutlet weak var containerView: UIView!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBOutlet weak var buttonForMenu: UIButton!
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
    var doubleTapGesture: UITapGestureRecognizer!
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
            self.trackUser = false
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
        self.mapView.gestureRecognizers?.forEach({ (gesture) in
            if (gesture is UITapGestureRecognizer) {
                let gr = gesture as! UITapGestureRecognizer
                if (gr.numberOfTapsRequired == 2) {
                    print("removing and adding")
                    self.mapView.removeGestureRecognizer(gr)
                    self.doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(determineDoubleTapAction))
                    self.doubleTapGesture.delegate = self
                    self.doubleTapGesture.numberOfTapsRequired = 2
                    self.mapView.addGestureRecognizer(self.doubleTapGesture)
                }
            }
        })
        view.insertSubview(self.mapView, at: 0)
        self.mapView.compassView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.mapView.snp.top).offset(80).priority(1000.0)
            make.right.equalTo(self.mapView.snp.right).offset(-30).priority(1000.0)
        }
        self.appDelegate.mapController = self        
    }
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 4
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        if (index == 0) {
            self.centerBox.isHidden = true
            return coachMarksController.helper.makeCoachMark(for: self.centerBox)
        } else if (index == 1) {
            return coachMarksController.helper.makeCoachMark(for: self.buttonForMenu)
        } else if (index == 2) {
            return coachMarksController.helper.makeCoachMark(for: self.searchBar)
        } else {
            self.icon.isHidden = false
            return coachMarksController.helper.makeCoachMark(for: self.icon)
        }
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        if (index == 0) {
            coachViews.bodyView.hintLabel.text = "This is you! You can double tap anywhere on the map to bring up an alert box asking if you'd like to take a photo  (line doesn't work yet)"
            coachViews.bodyView.nextLabel.text = "Sweet!"
        } else if (index == 1) {
            coachViews.bodyView.hintLabel.text = "This is the menu button! From here you can log in, sign up, change the color of the map, etc."
            coachViews.bodyView.nextLabel.text = "Ok!"
        } else if (index == 2) {
            coachViews.bodyView.hintLabel.text = "This is the search bar! You can enter an address or a place and the map will move to that location"
            coachViews.bodyView.nextLabel.text = "Ok!"
        } else {
            coachViews.bodyView.hintLabel.text = "Finally, if you move the map, this button will appear and will let you return the map to following your movements, if you want."
            coachViews.bodyView.nextLabel.text = "Ok!"
        }
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    func coachMarksController(_ coachMarksController: CoachMarksController, willShow coachMark: inout CoachMark, afterSizeTransition: Bool, at index: Int) {
        print("index: \(index)")
    }
    func coachMarksController(_ coachMarksController: CoachMarksController, willHide coachMark: CoachMark, at index: Int) {
        if (index == 3) {
            self.icon.isHidden = true
            self.appDelegate.setCoachMarksComplete(inView: "map", completed: true)
        }
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        self.appDelegate.setCoachMarksComplete(inView: "map", completed: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupMap()
        self.appDelegate.getSettings()
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
        //setupViews(portrait_oriented)
        self.centerBox.translatesAutoresizingMaskIntoConstraints = false
        self.centerBox.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self.view.snp.centerX).priority(1000.0)
            make.centerY.equalTo(self.view.snp.centerY).priority(1000.0)
            make.height.equalTo(60).priority(1000.0)
            make.width.equalTo(60).priority(1000.0)
        }
        self.centerBox.backgroundColor = UIColor.clear
        self.centerBox.isHidden = true
        self.coachMarksController.dataSource = self
        self.coachMarksController.delegate = self
        coachMarkSkip.setTitle("Skip", for: .normal)
        coachMarkSkip.setTitleColor(UIColor.white, for: .normal)
        coachMarkSkip.setBackgroundImage(nil, for: .normal)
        coachMarkSkip.setBackgroundImage(nil, for: .highlighted)
        coachMarkSkip.layer.cornerRadius = 0
        coachMarkSkip.backgroundColor = UIColor.darkGray
        self.coachMarksController.skipView = self.coachMarkSkip
        
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, constraintsForSkipView skipView: UIView, inParent parentView: UIView) -> [NSLayoutConstraint]? {
        skipView.snp.remakeConstraints { (make) in
            make.bottom.equalTo(parentView.snp.bottomMargin).priority(1000.0)
            make.centerX.equalTo(parentView.snp.centerX).priority(1000.0)
            make.width.equalTo(200).priority(1000.0)
            make.height.equalTo(50).priority(1000.0)
        }

        return skipView.constraints
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // start the views
        if (!self.appDelegate.getCoachMarksComplete(inView: "map")) {
            self.coachMarksController.start(on: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.coachMarksController.stop(immediately: true)
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
    
    @objc func determineDoubleTapAction(gestureRecognizer:UIGestureRecognizer) {
        let touched = gestureRecognizer.location(in: self.mapView)
        self.coordTouched = mapView.convert(touched, toCoordinateFrom: self.mapView)
        if (self.addingLine) {
            if (self.line.count < 2) {
                // put another point on the map
                var mapMarker: MapMarker!
                if let heading = self.userHeading {
                    mapMarker = MapMarker(coordinate: self.coordTouched)
                    mapMarker.set_heading(heading: heading)
                } else {
                    mapMarker = MapMarker(coordinate: self.coordTouched)
                }
                mapMarker.type = .line
                mapMarker.tag = line.count
                self.updateCurrentLine(mapMarker)
            } else {
                let alertController = UIAlertController(title: "2 Points Max", message: "We only allow 2 points on a line, but you can move around the two points you currently have by long pressing them.", preferredStyle: UIAlertControllerStyle.actionSheet)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            // determine if user wants to add a line or a photo
            // 3d touch?
            let alertController = UIAlertController(title: "Line or Photo", message:
                "Would you like to draw a line or a photo?", preferredStyle: UIAlertControllerStyle.actionSheet)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Line", style: .default, handler: handleAlert))
            alertController.addAction(UIAlertAction(title: "Photo", style: .default, handler: handleAlert))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    @objc func handleAlert(action: UIAlertAction) {
        if (action.title == "Line") {
            self.line = [] // reset the line being added
            self.addingLine = true
            var mapMarker: MapMarker!
            if let heading = self.userHeading {
                mapMarker = MapMarker(coordinate: self.coordTouched)
                mapMarker.set_heading(heading: heading)
            } else {
                mapMarker = MapMarker(coordinate: self.coordTouched)
            }
            mapMarker.type = .line
            mapMarker.tag = self.line.count
            self.icon.isHidden = true
            self.updateCurrentLine(mapMarker)
            // handle putting the first point on the map with the coordinate in memory self.coordTouched
        } else {
            //create photo view controller and push onto navigation
            self.trackUser = false
            // when we add the possibility to add a photo for another location we should not user locationManager, but the touched coord
            self.appDelegate.user.set_location(location: locationManager.location!)
            //let vc = PhotoController(nibName: "PhotoController", bundle: nil)
            self.picker = UIImagePickerController()
            self.picker.delegate = self
            let alert = UIAlertController(title: "Library or Camera", message: "Get a photo from your library or camera?", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: handleCameraLibrary))
            alert.addAction(UIAlertAction(title: "Library", style: .default, handler: handleCameraLibrary))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func handleCameraLibrary(action: UIAlertAction) {
        if (action.title == "Camera") {
            self.picker.sourceType = .camera
            self.picker.cameraDevice = .rear
            self.picker.cameraCaptureMode = .photo
            self.picker.allowsEditing = false
            self.picker.showsCameraControls = true
            self.picker.cameraOverlayView = UIView()
            self.picker.videoQuality = .typeHigh
        } else if(action.title == "Library") {
            self.picker.sourceType = .photoLibrary
        }
        self.present(self.picker, animated: true, completion: nil)
    }
    
    
    
    @objc func updateCurrentLine(_ mapMarker: MapMarker?) {
        print("update line being called")
        if (self.line.count > 0) {
            self.mapView.removeAnnotations(self.line) // remove all current annotations for the line
            if (self.polyline != nil) {
                self.mapView.remove(self.polyline)
            }
        }
        if (mapMarker != nil) {
            self.line.append(mapMarker!)
        }
        self.mapView.addAnnotations(self.line)
        if (self.line.count > 1) {
            self.polyline = CurbmapPolyLine(coordinates: [self.line[0].coordinate, self.line[1].coordinate], count: 2)
            self.mapView.add(self.polyline)
            self.lineLooksGreatButton.isHidden = false
            self.lineCancelButton.isHidden = false
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.photoToPlace = pickedImage
            dismiss(animated: true, completion: nil)
            print(info)
            self.photoToPlace = pickedImage
            self.placePhoto()
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
    @objc func lineCancelled() {
        self.lineCancelButton.isHidden = true
        self.lineLooksGreatButton.isHidden = true
        self.zoomLevel = 15.0
        if (self.appDelegate.user.settings["follow"] == "y"){
            self.trackUser = true
        }
        self.addingLine = false
        
    }
    @objc func cancelled() {
        self.cancelButton.isHidden = true
        self.looksGreatButton.isHidden = true
        self.zoomLevel = 15.0
        if (self.appDelegate.user.settings["follow"] == "y"){
            self.trackUser = true
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
        if (manager.location != nil) {
            self.appDelegate.user.set_location(location: manager.location!)
        }
    }

    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
        guard annotation is MapMarker else {
            return nil
        }
        let ann = annotation as! MapMarker
        // For better performance, always try to reuse existing annotations. To use multiple different annotation views, change the reuse identifier for each.
        if (ann.type == .line) {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggableLinePoint") as? DraggableAnnotationView {
                annotationView.set_callback(function: self.updateCurrentLine)
                return annotationView
            } else {
                let annotationView = DraggableAnnotationView(reuseIdentifier: "draggableLinePoint", size: 50, type: .line)
                annotationView.set_callback(function: self.updateCurrentLine)
                return annotationView
            }
        } else if (ann.type == .photo){
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePhotoPoint") {
                return annotationView
            } else {
                return DraggableAnnotationView(reuseIdentifier: "draggablePhotoPoint", size: 50, type: .photo)
            }
        } else {
            print("adding this kind of annotation")
            let View = DraggableAnnotationView(reuseIdentifier: "undragable", size: 50, type: .line)
            View.isDraggable = false
            return View
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    @objc func placePhoto() {
        self.looksGreatButton.isEnabled = true
        // Display mapmarker
        // on mapMarker show little photo?
        // Then turn off dragging of map and add a pan gesture which moves the marker only
        self.zoomLevel = 17
        centerMapOnLocation(location: CLLocation(latitude: self.coordTouched.latitude, longitude: self.coordTouched.longitude))
        if (self.userHeading != nil) {
            self.photoAnnotation = MapMarker(coordinate: self.coordTouched)
            self.photoAnnotation.set_heading(heading: self.userHeading!)
        } else {
            self.photoAnnotation = MapMarker(coordinate: self.coordTouched)
        }
        self.photoAnnotation.type = .photo
        self.movingPhotoAnnotation = true
        self.mapView.addAnnotation(self.photoAnnotation)
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
extension PHPhotoLibrary {
    func save(imageData: Data, location: CLLocationCoordinate2D, heading: CLLocationDirection, appDelegate: AppDelegate, completed: Bool) {
        var placeholder: PHObjectPlaceholder!
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: .none)
                request.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
                placeholder = request.placeholderForCreatedAsset
            }, completionHandler: { (success, error) -> Void in
                if let error = error {
                    return
                }
                guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject else {
                    return
                }
                appDelegate.save_image_data(localIdentifier: placeholder.localIdentifier, heading: heading.magnitude, lat: location.latitude, lng: location.longitude, uploaded: completed)
            }
        )
    }
    
}
// :- Date -: https://stackoverflow.com/questions/28016578/swift-how-to-create-a-date-time-stamp-and-format-as-iso-8601-rfc-3339-utc-tim
extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
}



