//
//  PhotoController.swift
//  curbmap
//
//  Created by Eli Selkin on 1/3/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//
//
//  SwiftyCamViewController.swift
//  curbmap
//
//  Created by Eli Selkin on 12/26/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Alamofire
import OpenLocationCode
import SnapKit

class PhotoController: UIViewController, AVCapturePhotoCaptureDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var viewfinder: UIView!
    var captureButton: UIButton!
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var canSavePhotos = false
    var canCaptureVideo = false
    var capturePhotoOutput: AVCapturePhotoOutput?
    var flashButton: UIButton!
    var flashMode: AVCaptureDevice.FlashMode = .on
    var cancelButton: UIButton!
    var viewSize: CGSize!
    var previewImage: UIImageView!
    @objc var keep: UIButton!
    @objc var cancel: UIButton!
    
    @objc func createCentralViews() {
        DispatchQueue.main.async {
            self.viewfinder = UIView(frame: self.view.frame)
            self.viewfinder.translatesAutoresizingMaskIntoConstraints = false
            self.captureButton = UIButton()
            self.captureButton.frame.size = CGSize(width: 80, height: 80)
            self.captureButton.setImage(UIImage(named: "photo"), for: .normal)
            self.captureButton.backgroundColor = UIColor.clear
            self.flashButton = UIButton()
            self.flashButton.frame.size = CGSize(width:48, height:48)
            self.flashButton.setImage(UIImage(named: "flash"), for: .normal)
            self.flashButton.backgroundColor = UIColor.clear
            self.cancelButton = UIButton(type: .system)
            self.cancelButton.setTitle("Cancel", for: .normal)
            self.cancelButton.setTitleColor(UIColor.white, for: .normal)
            self.view.addSubview(self.viewfinder)
            self.view.addSubview(self.captureButton)
            self.view.addSubview(self.flashButton)
            self.view.addSubview(self.cancelButton)
            self.keep = UIButton(type: .system)
            self.keep.setTitle("Keep", for: .normal)
            self.cancel = UIButton(type: .system)
            self.cancel.setTitle("Cancel", for: .normal)
            self.keep.addTarget(self, action: #selector(self.keepPressed), for: .touchUpInside)
            self.cancel.addTarget(self, action: #selector(self.cancelPressed), for: .touchUpInside)

        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    @objc func setupCentralViews(_ firstTime: Int) {
         DispatchQueue.main.async {
            self.viewSize = self.view.frame.size
            print(self.viewSize)
            if ((UIApplication.shared.statusBarOrientation.isPortrait && self.viewSize.width > self.viewSize.height) ||
                    (!UIApplication.shared.statusBarOrientation.isPortrait && self.viewSize.width < self.viewSize.height)) {
                print("changing dim XXX")
                self.viewSize = CGSize(width: self.viewSize.height, height: self.viewSize.width)
            }
            print(self.viewSize)
            self.viewfinder.frame.size = self.viewSize
            
            self.viewfinder.snp.remakeConstraints({ (make) in
                make.top.equalTo(self.view.snp.top).priority(1000.0)
                make.leading.equalTo(self.view.snp.leading).priority(1000.0)
                make.trailing.equalTo(self.view.snp.trailing).priority(1000.0)
                make.width.equalTo(self.viewSize.width).priority(1000.0)
                make.height.equalTo(self.viewSize.height).priority(1000.0)
                make.bottom.equalTo(self.view.snp.bottom).priority(1000.0)
            })
            self.videoPreviewLayer?.frame = self.viewfinder.frame
            self.captureButton.snp.remakeConstraints({ (make) in
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
                make.centerX.equalTo(self.view.snp.centerX).priority(1000.0)
                make.width.equalTo(80).priority(1000.0)
                make.height.equalTo(80).priority(1000.0)
            })
            self.flashButton.snp.remakeConstraints({ (make) in
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
                make.centerX.equalTo(self.view.snp.centerX).offset(-90).priority(1000.0)
                make.width.equalTo(48).priority(1000.0)
                make.height.equalTo(48).priority(1000.0)
            })
            self.cancelButton.snp.remakeConstraints({ (make) in
                make.bottom.equalTo(self.view.snp.bottomMargin).priority(1000.0)
                make.centerX.equalTo(self.view.snp.centerX).offset(90).priority(1000.0)
                make.width.equalTo(100).priority(1000.0)
                make.height.equalTo(48).priority(1000.0)
            })
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
            if (firstTime == 1) {
                self.setupCameraLayer()
            }
        }
    }
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = self.videoPreviewLayer?.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
        self.setupCentralViews(0)
    }
    
    @objc func setupCameraLayer() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                DispatchQueue.main.async {
                    do {
                        //access granted
                        let input = try AVCaptureDeviceInput(device: self.captureDevice!)
                        self.captureSession = AVCaptureSession()
                        self.captureSession?.addInput(input)
                        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                        self.videoPreviewLayer?.frame = self.viewfinder.bounds
                        self.viewfinder.layer.addSublayer(self.videoPreviewLayer!)
                        self.captureSession?.startRunning()
                        self.canCaptureVideo = true
                        self.captureButton.addTarget(self, action: #selector(self.takePhoto), for: .touchUpInside)
                        self.flashButton.addTarget(self, action: #selector(self.toggleFlash), for: .touchUpInside)
                        self.cancelButton.addTarget(self, action: #selector(self.cancelPhoto), for: .touchUpInside)
                        self.capturePhotoOutput = AVCapturePhotoOutput()
                        self.capturePhotoOutput?.isHighResolutionCaptureEnabled = true
                        self.captureSession?.addOutput(self.capturePhotoOutput!)
                        
                    } catch {
                        // could not create layer!
                        print("error setting up view")
                    }
                }
            } else {
                // not allowed to create layer
                print("not allowed to use camera")
            }
        }
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.canSavePhotos = true
                } else {
                    print("cannot save the photos to camera roll")
                }
            })
        }
    }
    @objc func toggleFlash (_ sender: Any) {
        if (self.flashMode == .on) {
            self.flashMode = .off
            self.flashButton.setImage(UIImage(named: "flashoff"), for: .normal)
        } else {
            self.flashMode = .on
            self.flashButton.setImage(UIImage(named: "flash"), for: .normal)
        }
    }
    @objc func loadPhoto(_ sender: Any) {
        
    }
    @objc func takePhoto(_ sender: Any) {
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = self.flashMode
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    @objc func cancelPhoto(_ sender: Any) {
        
    }
    @objc func keepPressed(_ sender: Any) {
        print("keeping")
    }
    
    @objc func cancelPressed(_ sender: Any) {
        self.previewImage.removeFromSuperview()
        self.previewImage = nil
        self.keep.removeFromSuperview()
        self.cancel.removeFromSuperview()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        // Convert photo same buffer to a jpeg image data by using // AVCapturePhotoOutput
        guard let imageData =
            AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                return
        }
        guard let capturedImage = UIImage(data: imageData, scale: 1.0) else {
            return
        }
        self.displayPreview(capturedImage)
    }
    
    @objc func displayPreview(_ capturedImage: UIImage) {
        DispatchQueue.main.async {
            self.previewImage = UIImageView(image: capturedImage)
            self.previewImage.frame = self.view.frame
            self.previewImage.autoresizesSubviews = true
            self.view.addSubview(self.previewImage)
            self.view.addSubview(self.keep)
            self.view.addSubview(self.cancel)
            self.previewImage.snp.remakeConstraints { (make) in
                make.top.equalTo(self.view.snp.top).priority(1000.0)
                make.bottom.equalTo(self.view.snp.bottom).priority(1000.0)
                make.leading.equalTo(self.view.snp.leading).priority(1000.0)
                make.trailing.equalTo(self.view.snp.trailing).priority(1000.0)
            }
            self.keep.snp.remakeConstraints({ (make) in
                make.bottom.equalTo(self.view.snp.bottom).priority(1000)
                make.centerX.equalTo(self.view.snp.centerX).offset(-90).priority(100.0)
                make.width.equalTo(100).priority(1000)
                make.height.equalTo(50).priority(1000)
            })
            self.cancel.snp.remakeConstraints({ (make) in
                make.bottom.equalTo(self.view.snp.bottom).priority(1000)
                make.centerX.equalTo(self.view.snp.centerX).offset(90).priority(100.0)
                make.width.equalTo(100).priority(1000)
                make.height.equalTo(50).priority(1000)
            })

        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createCentralViews()
        if (UIApplication.shared.statusBarOrientation.isPortrait) {
            self.setupCentralViews(1)
        } else {
            self.setupCentralViews(2)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
