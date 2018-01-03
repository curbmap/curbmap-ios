//
//  SwiftyCamViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/26/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import SwiftyCam
import Alamofire
import OpenLocationCode
import SnapKit

class PhotoController: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    @IBOutlet weak var captureButton    : SwiftyCamButton!
    @IBOutlet weak var flashButton      : UIButton!
    var imageData: UIImage!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBAction func cancelPushed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func keepImage(_ sender: Any) {
        if (appDelegate.mapController != nil) {
            appDelegate.mapController.photoToPlace = self.imageData
            appDelegate.mapController.placePhoto()
        }
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func cancelImage(_ sender: Any) {
        previewView.isHidden = true
        self.captureButton.isEnabled = true
        self.captureButton.isHidden = false
        self.imageData = nil
    }
    @IBOutlet weak var preview: UIImageView!
    @IBOutlet weak var previewView: UIView!
    
    @IBAction func flashPressed(_ sender: Any) {
        print(flashEnabled)
        flashEnabled = !flashEnabled
        if (flashEnabled) {
            self.flashButton.setImage(UIImage(named: "flash"), for: .normal)
        } else {
            print("flashoff")
            self.flashButton.setImage(UIImage(named: "flashoff"), for: .normal)
        }
        self.view.reloadInputViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraDelegate = self
        audioEnabled = false
        doubleTapCameraSwitch = false
        flashEnabled = true
        pinchToZoom = true
        tapToFocus = true
        videoQuality = .high
        shouldUseDeviceOrientation = true
        allowAutoRotate = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.layoutIfNeeded()
        self.view.layoutSubviews()
        captureButton.delegate = self
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        // Called when takePhoto() is called or if a SwiftyCamButton initiates a tap gesture
        // Returns a UIImage captured from the current session
        self.preview.image = photo
        self.imageData = photo
        let imageSize = self.imageData.size
        self.preview.contentMode = .scaleAspectFit
        self.preview.sizeThatFits(imageSize)
        var imageViewCenter = self.preview.center
        imageViewCenter.x = CGRect(origin: self.view.frame.origin, size: self.view.frame.size).midX
        self.preview.center = imageViewCenter
        self.preview.layer.backgroundColor = UIColor.black.cgColor
        self.preview.clipsToBounds = true
        self.previewView.isHidden = false
        self.captureButton.isEnabled = false
        self.captureButton.isHidden = true
    }
    // - https://stackoverflow.com/questions/24074257/how-to-use-uicolorfromrgb-value-in-swift
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        // Called when a user initiates a tap gesture on the preview layer
        // Will only be called if tapToFocus = true
        // Returns a CGPoint of the tap location on the preview layer
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        // Called when a user initiates a pinch gesture on the preview layer
        // Will only be called if pinchToZoomn = true
        // Returns a CGFloat of the current zoom level
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

