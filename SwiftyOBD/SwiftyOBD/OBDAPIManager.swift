//
//  OBDAPIManager.swift
//  SwiftyOBD
//
//  Created by Hella on 06.10.16.
//  Copyright © 2016 Hella Ventures Berlin. All rights reserved.
//

import Foundation

class OBDAPIManager: NSObject {
    
    //SINGLETON INSTANCE
    static let sharedInstance = OBDAPIManager()
    
    //DELEGATE
    var delegate: OBDStreamManagerDelegate?
    
    //Parameters for Hella Ventures Diagnostics API
    var language = "EN" //Default Language
    var vin = "WBAES26C05D" //Default VIN, Only the first 11 digits
    var api_address = "https://api.eu.apiconnect.ibmcloud.com/hella-ventures-car-diagnostic-api/api/v1/dtc"
    var client_id: String? // Your client id from Bluemix API Connect
    var client_secret: String? // Your client secret from Bluemix API Connect
    
    fileprivate override init(){
        super.init()
    }
    
}
