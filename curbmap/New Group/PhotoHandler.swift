//
//  Photo.swift
//  curbmap
//
//  Created by Eli Selkin on 2/25/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import Photos
import AssetsLibrary
import AVFoundation
import RealmSwift
import OpenLocationCode

class PhotoHandler: NSObject {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    // singleton
    public static let sharedInstance = PhotoHandler()
    
    // MARK: - Attaching GPS EXIF dictionary to image
    // Attached EXIF data for GPS location and heading to rescaled larger photo with max dim 2000px
    // Resizes to smaller photo with maximum dim 700px
    func attachExif(photo: UIImage, annotation: MapMarker, heading_magnitude: Double, olc: String) -> (small: Data, large: Data) {
        let maxDim = max(photo.size.width, photo.size.height)
        let maxResizeDim = CGFloat(700.0)
        let lgMaxResizeDim = CGFloat(2000.0)
        let size = CGSize(width: maxResizeDim * (photo.size.width/maxDim), height: maxResizeDim * (photo.size.height/maxDim))
        let lg_size = CGSize(width: lgMaxResizeDim * (photo.size.width/maxDim), height: lgMaxResizeDim * (photo.size.height/maxDim))
        let tempSmallPhoto = photo.af_imageAspectScaled(toFit: size)
        let tempLargePhoto = photo.af_imageAspectScaled(toFit: lg_size)
        let smallImageData = UIImageJPEGRepresentation(tempSmallPhoto, 0.6)!
        let imageData = UIImageJPEGRepresentation(tempLargePhoto, 0.8)!
        let cgImgSource = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let uti:CFString = CGImageSourceGetType(cgImgSource)!
        let dataWithEXIF: NSMutableData = NSMutableData(data: imageData)
        let destination: CGImageDestination = CGImageDestinationCreateWithData((dataWithEXIF as CFMutableData), uti, 1, nil)!
        
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(cgImgSource, 0, nil)! as NSDictionary
        let mutable: NSMutableDictionary = imageProperties.mutableCopy() as! NSMutableDictionary
        let EXIFDictionary: NSMutableDictionary = (mutable[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary)!
        let GPSDictionary: NSMutableDictionary = NSMutableDictionary()
        GPSDictionary.setValue(NSNumber(floatLiteral: fabs(annotation.coordinate.latitude)), forKey: kCGImagePropertyGPSLatitude as String)
        GPSDictionary.setValue(NSNumber(floatLiteral: fabs(annotation.coordinate.latitude)), forKey: kCGImagePropertyGPSLatitude as String)
        GPSDictionary.setValue(NSNumber(floatLiteral: fabs(annotation.coordinate.latitude)), forKey: kCGImagePropertyGPSDestLatitude as String)
        if (annotation.coordinate.latitude > 0) {
            GPSDictionary.setValue( "N", forKey: kCGImagePropertyGPSLatitudeRef as String)
            GPSDictionary.setValue( "N", forKey: kCGImagePropertyGPSDestLatitudeRef as String)
            // north
        } else {
            // south
            GPSDictionary.setValue( "S", forKey: kCGImagePropertyGPSLatitudeRef as String)
            GPSDictionary.setValue( "S", forKey: kCGImagePropertyGPSDestLatitudeRef as String)
        }
        GPSDictionary.setValue( NSNumber(floatLiteral: fabs(annotation.coordinate.longitude)), forKey: kCGImagePropertyGPSLongitude as String)
        GPSDictionary.setValue( NSNumber(floatLiteral: fabs(annotation.coordinate.longitude)), forKey: kCGImagePropertyGPSDestLongitude as String)
        if (annotation.coordinate.longitude < 0) {
            // W
            GPSDictionary.setValue( "W", forKey: kCGImagePropertyGPSLongitudeRef as String)
            GPSDictionary.setValue( "W", forKey: kCGImagePropertyGPSDestLongitudeRef as String)
        } else {
            // E
            GPSDictionary.setValue( "E", forKey: kCGImagePropertyGPSLongitudeRef as String)
            GPSDictionary.setValue( "E", forKey: kCGImagePropertyGPSDestLongitudeRef as String)
        }
        GPSDictionary.setValue(NSNumber(floatLiteral: heading_magnitude), forKey: kCGImagePropertyGPSDestBearing as String)
        GPSDictionary.setValue("N", forKey: kCGImagePropertyGPSDestBearingRef as String)
        mutable.setValue(EXIFDictionary, forKey: kCGImagePropertyExifDictionary as String)
        mutable.setValue(GPSDictionary, forKey: kCGImagePropertyGPSDictionary as String)
        CGImageDestinationAddImageFromSource(destination, cgImgSource, 0, (mutable as CFDictionary))
        CGImageDestinationFinalize(destination)
        return(small: smallImageData, large: dataWithEXIF as Data);
    }
    
    func save(data: Data, olc: String, heading: CLLocationDirection) {
        // Saves to database
        DispatchQueue.main.async {
            let uuid = UUID().uuidString
            let newImage = Images()
            newImage.heading = heading
            newImage.olc = olc
            newImage.uploaded = false
            newImage.data = data
            newImage.localIdentifier = uuid
            try! self.appDelegate.realm.write {
                self.appDelegate.realm.add(newImage)
            }
            print ("NEW IMAGE", newImage)
            do {
                let codeArea = try OpenLocationCode.decode(code: olc)
                let M = MapMarker(coordinate: CLLocationCoordinate2D(latitude: codeArea.LatLng().latitude, longitude: codeArea.LatLng().longitude))
                M.type = MapMarker.AnnotationType.photoNotDraggable
                M.heading = heading
                self.appDelegate.photosToDraw.append(M)
                if (self.appDelegate.mapController != nil) {
                    self.appDelegate.mapController.triggerDrawLines()
                }
            } catch (let error) {
                print(error);
            }
        }
    }

    // just a wrapper so I can make upload async sub-tasks
    func upload(_ photos: [Images]){
        for image in photos {
            self.upload(photo: image)
        }
    }
    
    func upload(photo: Images){
        // Gets the data out of the db in main async, but will send the data
        // to the server in background
        DispatchQueue.main.async {
            let imageData = photo.data
            let imageOLC = photo.olc
            let imageHeading = photo.heading
            self.sendImage(imageData: imageData, imageOLC: imageOLC, imageHeading: imageHeading, photo: photo)
        }
    }
    
    func sendImage(imageData: Data, imageOLC: String, imageHeading: Double, photo: Images) {
        DispatchQueue.global(qos: .background).async {
            let headers = [
                "Content-Type": "application/x-www-form-urlencoded",
                "username": self.appDelegate.user.get_username(),
                "session": self.appDelegate.user.get_session()
            ]
            Alamofire.upload(multipartFormData: { MultipartFormData in
                MultipartFormData.append(imageData, withName: "image", fileName: "\(Date().iso8601).jpg", mimeType: "image/jpeg")
                MultipartFormData.append(imageOLC.data(using: String.Encoding.utf8)!, withName: "olc")
                MultipartFormData.append("\(imageHeading)".data(using: String.Encoding.utf8)!, withName: "bearing")
            } , usingThreshold:UInt64.init(), to: "https://curbmap.com:50003/imageUpload", method: .post, headers: headers, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        if let result = response.result.value {
                            if let success = result as? NSDictionary {
                                if ((success["success"]! as! Bool) == true) {
                                    self.updatePhoto(photo)
                                }
                                return
                            }
                            
                        }
                    }
                    break
                case .failure(let encodingError):
                    print("failed to send \(encodingError.localizedDescription)")
                }
            })
        }
    }
    
    func sendImage(imageData: Data, imageOLC: String, imageHeading: Double, token: String) {
        DispatchQueue.global(qos: .background).async {
            let headers = [
                "Content-Type": "application/x-www-form-urlencoded",
                "username": self.appDelegate.user.get_username(),
                "session": self.appDelegate.user.get_session()
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .full
            dateFormatter.dateStyle = .full
            dateFormatter.timeZone = Calendar.current.timeZone
            Alamofire.upload(multipartFormData: { MultipartFormData in
                MultipartFormData.append("ios".data(using: String.Encoding.utf8)!, withName: "device")
                MultipartFormData.append(token.data(using: .utf8)!, withName: "token")
                MultipartFormData.append("\(dateFormatter.string(from: Date()))".data(using: String.Encoding.utf8)!, withName: "date")
                MultipartFormData.append(imageOLC.data(using: String.Encoding.utf8)!, withName: "olc")
                MultipartFormData.append("\(imageHeading)".data(using: String.Encoding.utf8)!, withName: "bearing")
                MultipartFormData.append(imageData, withName: "image", fileName: "\(Date().iso8601).jpg", mimeType: "image/jpeg")
            }, usingThreshold:UInt64.init(), to: "https://curbmap.com:50003/imageUploadText", method: .post, headers: headers, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        if let result = response.result.value {
                            if let success = result as? NSDictionary {
                                print("success")
                            }
                            
                        }
                    }
                    break
                case .failure(let encodingError):
                    print("failed to send \(encodingError.localizedDescription)")
                }
            })
        }
    }
    
    func updatePhoto(_ photo: Images) {
        DispatchQueue.main.async {
            try! self.appDelegate.realm.write {
                photo.uploaded = true
            }
        }
    }
}

class Images: Object {
    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var heading: Double = 0.0
    @objc dynamic var olc: String = ""
    @objc dynamic var uploaded: Bool = false
    @objc dynamic var data: Data = Data()
}

