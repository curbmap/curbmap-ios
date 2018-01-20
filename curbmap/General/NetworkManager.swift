//
//  NetworkManager.swift
//  curbmap
//
//  Created by Eli Selkin on 1/13/18.
//  Copyright © 2018 Eli Selkin. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

// https://stackoverflow.com/a/39766766
class NetworkManager {
    
    //shared instance
    static let shared = NetworkManager()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "curbmap.com")
    
    func startNetworkReachabilityObserver() {
        
        reachabilityManager?.listener = { status in
            switch status {
            case .reachable(.ethernetOrWiFi):
                print("The network is reachable over the WiFi connection")
            default:
                break                
            }
        }
        
        // start listening
        reachabilityManager?.startListening()
    }
}
