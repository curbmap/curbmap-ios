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
    func updatePhoto(_ photo: Images) {
        DispatchQueue.main.async {
            try! self.appDelegate.realm.write {
                photo.uploaded = true
            }
        }
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
    func upload(_ photos: [Images]){
        print("Photos:", photos.count)
        for image in photos {
            print(image)
        }
        for image in photos {
            self.upload(photo: image)
        }
    }
    
    func upload(photo: Images){
        // do something
        DispatchQueue.main.async {
            let imageData = photo.data as! Data
            let image = UIImage(data:imageData, scale: 1.0)
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
}

class Images: Object {
    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var heading: Double = 0.0
    @objc dynamic var olc: String = ""
    @objc dynamic var uploaded: Bool = false
    @objc dynamic var data: Data = Data()
}

