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
import AlamofireImage
import OpenLocationCode
import Mapbox
import Instructions
import SnapKit
import Photos
import AssetsLibrary
import AVFoundation
import Mixpanel

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, CoachMarksControllerDataSource, CoachMarksControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var viewSize: CGSize!
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
    var alertCameraOrLineViewBG: UIView!
    var alertCameraOrLineViewFG: UIView!
    let photoMessages = ["Your photos are beautiful. Ansel Adams would be jealous."]
    let photoImages = ["greatphoto0"]
    let lineMessages = ["Thank you for adding such a beautiful line. It's the best line. Nobody makes any better lines!"]
    let lineImages = ["greatline0"]
    let responseMessages = ["Yay!", "Excellent!", "I'm glad I helped", "I'd do it again!"]
    var selectedLine: CurbmapPolyLine!
    @IBAction func alertAddLine(_ sender: Any) {
        self.alertCameraOrLineViewBG.removeFromSuperview()
        self.alertCameraOrLineViewBG = nil
        self.alertCameraOrLineViewFG.removeFromSuperview()
        self.alertCameraOrLineViewFG = nil
        handleAlert(action: "Line")
    }
    @IBAction func alertAddPhoto(_ sender: Any) {
        self.alertCameraOrLineViewBG.removeFromSuperview()
        self.alertCameraOrLineViewBG = nil
        self.alertCameraOrLineViewFG.removeFromSuperview()
        self.alertCameraOrLineViewFG = nil
        handleAlert(action: "Photo")
    }
    @IBAction func alertCancel(_ sender: Any) {
        self.alertCameraOrLineViewBG.removeFromSuperview()
        self.alertCameraOrLineViewBG = nil
        self.alertCameraOrLineViewFG.removeFromSuperview()
        self.alertCameraOrLineViewFG = nil
    }
    func createThankYouAlert(isPhoto photo: Bool) {
        guard self.alertCameraOrLineViewBG == nil else {
            return
        }
        let alertImageView = UIImageView()
        let alertLabel = UILabel()
        if (photo) {
            let randomIdx = Int(arc4random_uniform(UInt32(photoImages.count)))
            alertImageView.image = UIImage(named: photoImages[randomIdx])
            alertLabel.text = photoMessages[randomIdx]
        } else {
            let randomIdx = Int(arc4random_uniform(UInt32(lineImages.count)))
            alertImageView.image = UIImage(named: lineImages[randomIdx])
            alertLabel.text = lineMessages[randomIdx]
        }
        let randomIdx = Int(arc4random_uniform(UInt32(responseMessages.count)))
        alertLabel.adjustsFontForContentSizeCategory = true
        let alertCancelButton = UIButton(type: .system)
        alertCancelButton.setTitle(responseMessages[randomIdx], for: .normal)
        alertCancelButton.addTarget(self, action: #selector(alertCancel), for: .touchUpInside)
        self.alertCameraOrLineViewBG = UIView()
        self.alertCameraOrLineViewBG.backgroundColor = UIColor.clear
        self.alertCameraOrLineViewBG.layer.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3).cgColor
        self.alertCameraOrLineViewBG.isOpaque = false
        self.alertCameraOrLineViewBG.alpha = 0.4
        self.alertCameraOrLineViewFG = UIView()
        alertCameraOrLineViewFG.backgroundColor = UIColor.white
        alertCameraOrLineViewFG.layer.cornerRadius = 10.0
        alertCameraOrLineViewFG.addSubview(alertImageView)
        alertCameraOrLineViewFG.addSubview(alertLabel)
        alertCameraOrLineViewFG.addSubview(alertCancelButton)
        self.alertCameraOrLineViewBG.isHidden = false
        self.alertCameraOrLineViewFG.isHidden = false
        self.view.addSubview(alertCameraOrLineViewBG)
        self.view.addSubview(alertCameraOrLineViewFG)
        let viewSize = self.view.frame.size
        self.alertCameraOrLineViewBG.snp.remakeConstraints { (make) in
            make.center.equalTo(self.view.snp.center).priority(1000)
            make.height.equalTo(self.view.snp.height).priority(1000)
            make.width.equalTo(self.view.snp.width).priority(1000)
        }
        alertCameraOrLineViewFG.snp.remakeConstraints { (make) in
            make.center.equalTo(self.view.snp.center).priority(1000.0)
            if (viewSize.height < viewSize.width) {
                make.height.equalTo(self.view.snp.height).dividedBy(1.3).priority(1000.0)
                make.width.equalTo(self.view.snp.width).dividedBy(2).priority(1000.0)
            } else {
                make.height.equalTo(self.view.snp.height).dividedBy(2).priority(1000.0)
                make.width.equalTo(self.view.snp.width).dividedBy(1.3).priority(1000.0)
            }
        }
        self.alertCameraOrLineViewFG.backgroundColor = UIColor.white
        alertImageView.snp.remakeConstraints { (make) in
            make.top.equalTo(alertCameraOrLineViewFG.snp.top).priority(1000.0)
            make.centerX.equalTo(alertCameraOrLineViewFG.snp.centerX).priority(1000.0)
            make.height.equalTo(alertCameraOrLineViewFG.snp.height).dividedBy(3.3).priority(1000)
            make.width.equalTo(alertImageView.snp.height).priority(1000)
        }
        
        alertLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(alertImageView.snp.bottom).offset(8).priority(1000.0)
            make.leading.equalTo(alertCameraOrLineViewFG.snp.leadingMargin).offset(15).priority(1000.0)
            make.trailing.equalTo(alertCameraOrLineViewFG.snp.trailingMargin).inset(15).priority(1000.0)
            make.bottom.equalTo(alertCancelButton.snp.top).offset(8).priority(1000)
            make.height.equalTo(alertCameraOrLineViewFG.snp.height).dividedBy(2).priority(1000.0)
        }
        alertLabel.numberOfLines = 0
        alertLabel.lineBreakMode = .byWordWrapping
        alertLabel.textAlignment = .left
        alertCancelButton.snp.remakeConstraints { (make) in
            make.bottom.equalTo(alertCameraOrLineViewFG.snp.bottomMargin).offset(0).priority(1000.0)
            make.centerX.equalTo(alertCameraOrLineViewFG.snp.centerX).priority(1000.0)
            make.width.equalTo(alertCameraOrLineViewFG.snp.width).priority(1000)
            make.height.equalTo(alertCameraOrLineViewFG.snp.height).dividedBy(5.1).priority(1000)
        }
        
    }
    func createAlertForCameraOrLineView() {
        guard self.alertCameraOrLineViewBG == nil else {
            return
        }
        let alertLabel = UILabel()
        alertLabel.text = "You can add a line or a photo at the point you tapped. Don't worry if it's not exactly the right place. You can move the points once they are on the map :-)"
        alertLabel.adjustsFontForContentSizeCategory = true
        let alertCameraButton = UIButton(type: .system)
        alertCameraButton.setTitle("add a photo", for: .normal)
        alertCameraButton.addTarget(self, action: #selector(alertAddPhoto), for: .touchUpInside)
        let alertLineButton = UIButton(type: .system)
        alertLineButton.setTitle("add a line", for: .normal)
        alertLineButton.addTarget(self, action: #selector(alertAddLine), for: .touchUpInside)
        let alertCancelButton = UIButton(type: .system)
        alertCancelButton.setTitle("cancel", for: .normal)
        alertCancelButton.addTarget(self, action: #selector(alertCancel), for: .touchUpInside)
        self.alertCameraOrLineViewBG = UIView()
        self.alertCameraOrLineViewBG.backgroundColor = UIColor.clear
        self.alertCameraOrLineViewBG.layer.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.2).cgColor
        self.alertCameraOrLineViewBG.isOpaque = false
        self.alertCameraOrLineViewBG.alpha = 0.5
        self.alertCameraOrLineViewFG = UIView()
        alertCameraOrLineViewFG.backgroundColor = UIColor.white
        alertCameraOrLineViewFG.layer.cornerRadius = 10.0
        alertCameraOrLineViewFG.addSubview(alertLabel)
        alertCameraOrLineViewFG.addSubview(alertCameraButton)
        alertCameraOrLineViewFG.addSubview(alertLineButton)
        alertCameraOrLineViewFG.addSubview(alertCancelButton)
        self.alertCameraOrLineViewBG.isHidden = false
        self.alertCameraOrLineViewFG.isHidden = false
        self.view.addSubview(alertCameraOrLineViewBG)
        self.view.addSubview(alertCameraOrLineViewFG)
        let viewSize = self.view.frame.size
        self.alertCameraOrLineViewBG.snp.remakeConstraints { (make) in
            make.center.equalTo(self.view.snp.center).priority(1000)
            make.height.equalTo(self.view.snp.height).priority(1000)
            make.width.equalTo(self.view.snp.width).priority(1000)
        }
        alertCameraOrLineViewFG.snp.remakeConstraints { (make) in
            make.center.equalTo(self.view.snp.center).priority(1000.0)
            if (viewSize.height < viewSize.width) {
                make.height.equalTo(self.view.snp.height).dividedBy(1.3).priority(1000.0)
                make.width.equalTo(self.view.snp.width).dividedBy(2).priority(1000.0)
            } else {
                make.height.equalTo(self.view.snp.height).dividedBy(2).priority(1000.0)
                make.width.equalTo(self.view.snp.width).dividedBy(1.3).priority(1000.0)
            }
        }
        self.alertCameraOrLineViewFG.backgroundColor = UIColor.white
        alertLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(alertCameraOrLineViewFG.snp.top).priority(1000.0)
            make.leading.equalTo(alertCameraOrLineViewFG.snp.leadingMargin).offset(15).priority(1000.0)
            make.trailing.equalTo(alertCameraOrLineViewFG.snp.trailingMargin).inset(15).priority(1000.0)
            make.height.equalTo(alertCameraOrLineViewFG.snp.height).dividedBy(1.5).priority(1000.0)
        }
        alertLabel.numberOfLines = 0
        alertLabel.lineBreakMode = .byWordWrapping
        alertLabel.textAlignment = .left
        alertCameraButton.snp.remakeConstraints { (make) in
            make.top.equalTo(alertLabel.snp.bottom).priority(1000.0)
            make.leading.equalTo(alertCameraOrLineViewFG.snp.leadingMargin).offset(15).priority(1000.0)
        }
        alertLineButton.snp.remakeConstraints { (make) in
            make.top.equalTo(alertLabel.snp.bottom).priority(1000.0)
            make.trailing.equalTo(alertCameraOrLineViewFG.snp.trailingMargin).inset(15).priority(1000.0)
        }
        alertCancelButton.snp.remakeConstraints { (make) in
            make.bottom.equalTo(alertCameraOrLineViewFG.snp.bottomMargin).priority(1000.0)
            make.centerX.equalTo(alertCameraOrLineViewFG.snp.centerX).priority(1000.0)
        }
    }
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var lineCancelButton: UIButton!
    
    @IBAction func cancel(_ sender: Any) {
        self.mapView.removeAnnotation(photoAnnotation)
        Mixpanel.mainInstance().track(event: "double_tapped_photo",
                                      properties: ["photo cancelled": "yes",
                                                   "on wifi": "no"])
        self.cancelled()
    }
    @IBAction func cancelLine(_ sender: Any) {
        self.mapView.removeAnnotations(self.line)
        self.mapView.remove(self.polyline)
        self.lineCancelled()
    }
    @IBAction func doneWithLine(_ sender: Any) {
        createThankYouAlert(isPhoto: false)
        self.cancelLine(self)
        self.triggerDrawLines()
        // show cute message
        
    }
    
    @IBOutlet weak var looksGreatButton: UIButton!
    @IBOutlet weak var lineLooksGreatButton: UIButton!
    
    @IBAction func looksGreat(_ sender: Any) {
        self.looksGreatButton.isEnabled = false
        if (self.photoAnnotation != nil) {
            let olc = try? OpenLocationCode.encode(latitude: self.photoAnnotation.coordinate.latitude, longitude: self.photoAnnotation.coordinate.longitude, codeLength: 12)
            var heading_magnitude = 0.0
            if let heading = self.photoAnnotation.heading {
                heading_magnitude = heading.magnitude
            }
            if (olc != nil) {
                let imagesTuple = PhotoHandler.sharedInstance.attachExif(photo: self.photoToPlace, annotation: self.photoAnnotation, heading_magnitude: heading_magnitude, olc: olc!)
                PhotoHandler.sharedInstance.sendText(imageData: imagesTuple.small, imageOLC: olc!, imageHeading: heading_magnitude, token: self.appDelegate.token!, retries: 0, retriesMax: 4)
                Mixpanel.mainInstance().track(event: "double_tapped_photo",
                                              properties: ["photo added": self.appDelegate.restrictions.count,
                                                           "on wifi": (NetworkReachabilityManager()?.isReachableOnEthernetOrWiFi)!,
                                                           "olc": olc!])
                createThankYouAlert(isPhoto: true)
                self.mapView.removeAnnotations([self.photoAnnotation!])
                PhotoHandler.sharedInstance.save(data: imagesTuple.large, olc: olc!, heading: heading_magnitude)
                self.cancelled()
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
    var tableView: UITableView!
    var menuOpen = false
    // Hide table view tap on map or button
    @IBOutlet weak var buttonForMenu: UIButton!
    @IBAction func menuButton(_ sender: Any) {
        self.containerView.isHidden = menuOpen
        menuOpen = !menuOpen
        self.menuTableViewController.tableView.reloadData()
    }
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchSettingsButton: UIButton!
    @IBAction func searchSettingsButtonPressed(_ sender: Any) {
        let vc = SearchSettingsViewController(nibName: "SearchSettingsViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
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
            "token": appDelegate.user.get_token(),
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
        geocoder.geocodeAddressString((searchBar.text)!, completionHandler: { (placemarks, error) in
            // Process Response
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
    
    @objc func setupCentralViews(_ firstTime: Int) {
        viewSize = self.view.frame.size
        
        if ((firstTime != 1 && firstTime != 2) &&
            ((!UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width > viewSize.height) ||
                (UIApplication.shared.statusBarOrientation.isPortrait && viewSize.width < viewSize.height))) {
            viewSize = CGSize(width: viewSize.height, height: viewSize.width)
        }
        
        self.buttonForMenu.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leading).priority(1000.0)
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.width.equalTo(64).priority(1000.0)
            make.height.equalTo(64).priority(1000.0)
        }
        // They should call it wasPortrait
        self.containerView.snp.remakeConstraints({(make) in
            make.leading.equalTo(self.buttonForMenu.snp.leading).priority(1000.0)
            make.top.equalTo(self.buttonForMenu.snp.bottom).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin)
            if (viewSize.width < viewSize.height) {
                make.width.equalTo(viewSize.width/1.5).priority(1000.0)
            } else {
                make.width.equalTo(viewSize.width/2.0).priority(1000.0)
            }
        })
        self.tableView.frame = self.containerView.frame
        self.tableView.snp.remakeConstraints { (make) in
            make.width.equalTo(self.containerView.snp.width).priority(1000.0)
            make.height.equalTo(self.containerView.snp.height).priority(1000.0)
            make.leading.equalTo(self.containerView.snp.leading).priority(1000.0)
            make.trailing.equalTo(self.containerView.snp.trailing).priority(1000.0)
            make.top.equalTo(self.containerView.snp.top).priority(1000.0)
            make.bottom.equalTo(self.containerView.snp.bottom).priority(1000.0)
        }
        self.icon.snp.remakeConstraints { (make) in
            make.trailing.equalTo(self.view.snp.trailingMargin).inset(25).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(25).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
            make.width.equalTo(48).priority(1000.0)
        }
        self.cancelButton.snp.remakeConstraints { (make) in
            make.trailing.equalTo(self.view.snp.trailingMargin).inset(30).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(30).priority(1000.0)
            make.height.equalTo(80).priority(1000.0)
            make.width.equalTo(80).priority(1000.0)
        }
        self.lineCancelButton.snp.remakeConstraints { (make) in
            make.trailing.equalTo(self.view.snp.trailingMargin).inset(30).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(30).priority(1000.0)
            make.height.equalTo(80).priority(1000.0)
            make.width.equalTo(80).priority(1000.0)
        }
        self.looksGreatButton.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).offset(30).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(30).priority(1000.0)
            make.height.equalTo(80).priority(1000.0)
            make.width.equalTo(80).priority(1000.0)
        }
        self.lineLooksGreatButton.snp.remakeConstraints { (make) in
            make.leading.equalTo(self.view.snp.leadingMargin).offset(30).priority(1000.0)
            make.bottom.equalTo(self.view.snp.bottomMargin).inset(30).priority(1000.0)
            make.height.equalTo(80).priority(1000.0)
            make.width.equalTo(80).priority(1000.0)
        }
        self.searchBar.snp.remakeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).priority(1000.0)
            make.leading.equalTo(self.buttonForMenu.snp.trailing).priority(1000.0)
            make.height.equalTo(self.buttonForMenu.snp.height).priority(1000.0)
            make.trailing.equalTo(self.searchSettingsButton.snp.leading).priority(1000.0)
        }
        self.searchSettingsButton.snp.remakeConstraints { (make) in
            make.centerY.equalTo(self.searchBar.snp.centerY).priority(1000.0)
            make.trailing.equalTo(self.view.snp.trailing).priority(1000.0)
            make.width.equalTo(48).priority(1000.0)
            make.height.equalTo(48).priority(1000.0)
        }
        
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
        menuTableViewController = MenuTableViewController(nibName: "MenuTableViewController", bundle: nil)
        menuTableViewController.willMove(toParentViewController: self)
        self.containerView.addSubview(menuTableViewController.tableView)
        self.tableView = menuTableViewController.tableView
        self.addChildViewController(menuTableViewController)
        menuTableViewController.didMove(toParentViewController: self)
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            self.setupCentralViews(1)
        } else {
            self.setupCentralViews(2)
        }
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
        self.mapView.addGestureRecognizer(tap)
        self.searchBar.delegate = self
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
        self.triggerDrawLines()
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
            if (self.line.count < 4) {
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
                let alertController = UIAlertController(title: "4 Points Max", message: "We only allow 4 points on a line, but you can move around the points you currently have by long pressing them.", preferredStyle: UIAlertControllerStyle.actionSheet)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            // determine if user wants to add a line or a photo
            // 3d touch?
            self.createAlertForCameraOrLineView()
        }
    }
    @objc func handleAlert(action: String) {
        if (action == "Line") {
            Mixpanel.mainInstance().time(event: "double_tapped_line")
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
            Mixpanel.mainInstance().time(event: "double_tapped_photo")
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
            var coordinatesArray: [CLLocationCoordinate2D] = []
            for point in self.line {
                coordinatesArray.append(point.coordinate)
            }
            self.polyline = CurbmapPolyLine(coordinates: coordinatesArray, count: UInt(coordinatesArray.count))
            self.polyline.color = UIColor.magenta
            self.mapView.add(self.polyline)
            self.lineLooksGreatButton.isHidden = false
            self.lineCancelButton.isHidden = false
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.photoToPlace = pickedImage
            dismiss(animated: true, completion: nil)
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
            if (self.alertCameraOrLineViewBG != nil) {
                self.alertCameraOrLineViewBG.removeFromSuperview()
                self.alertCameraOrLineViewFG.removeFromSuperview()
                self.alertCameraOrLineViewBG = nil
                self.alertCameraOrLineViewFG = nil
                self.createAlertForCameraOrLineView()
            }
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
        Mixpanel.mainInstance().track(event: "double_tapped_line", properties: ["number of restrictions added": -1])
        self.lineCancelButton.isHidden = true
        self.lineLooksGreatButton.isHidden = true
        self.zoomLevel = 15.0
        if (self.appDelegate.user.settings["follow"] == "y"){
            self.trackUser = true
        }
        self.addingLine = false
    }
    @objc func cancelled() {
        DispatchQueue.main.async {
            self.cancelButton.isHidden = true
            self.looksGreatButton.isHidden = true
            self.zoomLevel = 15.0
            if (self.appDelegate.user.settings["follow"] == "y"){
                self.trackUser = true
            }
            
            self.movingPhotoAnnotation = false
            self.photoAnnotation = nil
            self.photoToPlace = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    // do stuff
                    self.locationManager.startUpdatingLocation()
                    self.locationManager.startUpdatingHeading()
                    if (self.locationManager.location != nil) {
                        self.centerMapOnLocation(location: self.locationManager.location!)
                    }
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
        } else if (ann.type == .lineNotDraggable){
            let View = DraggableAnnotationView(reuseIdentifier: "undraggableLine", size: 50, type: .lineNotDraggable)
            View.isDraggable = false
            return View
        } else {
            let View = DraggableAnnotationView(reuseIdentifier: "undraggablePhoto", size: 50, type: .photoNotDraggable)
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
        self.photoAnnotation = MapMarker(coordinate: self.coordTouched)
        if (self.userHeading != nil) {
            self.photoAnnotation.set_heading(heading: self.userHeading!)
        }
        self.photoAnnotation.type = .photo
        if (self.picker.sourceType == .camera) {
            self.photoAnnotation.fromLibrary = false
        } else {
            self.photoAnnotation.fromLibrary = true
        }
        self.movingPhotoAnnotation = true
        self.mapView.addAnnotation(self.photoAnnotation)
        self.looksGreatButton.isHidden = false
        self.cancelButton.isHidden = false
        self.icon.isHidden = true
    }
    
    func triggerDrawLines() {
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
        if let annotations = self.mapView.annotations {
            self.mapView.removeAnnotations(annotations)
        }
        self.mapView.addOverlays(self.appDelegate.linesToDraw)
        self.mapView.addAnnotations(self.appDelegate.photosToDraw)
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        if (annotation == self.selectedLine) {
            return 4.0
        } else {
            return 2.0
        }
    }
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.9
    }
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if (annotation.isKind(of: CurbmapPolyLine.self)) {
            let annotationCPL = annotation as! CurbmapPolyLine
            return annotationCPL.color!
        } else {
            return UIColor.blue
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UITableViewController,
            segue.identifier == "ShowMenuFromMap" {
            self.menuTableViewController = vc
        }
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

