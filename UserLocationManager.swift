//
//  UserLocationManager.swift
//  BestIdAttendance
//
//  Created by xamarin developer on 22/11/2018.
//  Copyright © 2018 Bestinet. All rights reserved.
//

import CoreLocation

protocol LocationUpdateProtocol {
    func didUpdateTo(location : CLLocation)
    func didChangeAuthorizationInLocationSettings(status: String)
    
    // Oprtional Methods - 100% swift way
    func getCurrLocFull(details : Dictionary<String, Any>)
    func didFailWithErrorsWhenReadLocations(errors : String)
}

extension LocationUpdateProtocol {
    func getCurrLocFull(details : Dictionary<String, Any>) {
        // this is a empty implementation to allow this method to be optional
    }
    
    func didFailWithErrorsWhenReadLocations(errors : String) {
        
    }
}


/// Notification on update of location. UserInfo contains CLLocation for key "location"
let kLocationDidChangeNotification = "LocationDidChangeNotification"

class UserLocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = UserLocationManager()

    private var locationManager = CLLocationManager()
    var currentLocation : CLLocation?
    var delegate : LocationUpdateProtocol!
    
    var currLocDetails : Dictionary<String, Any>?
    
    private override init () {}
    
    func startLocationManager() {
        print("start loc manager")
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func stopLocationManager() {
        self.locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("did UpdateToLocation")
        self.currentLocation = locations.last
        
        self.currLocDetails = ["latitude": locations.last?.coordinate.latitude ?? 0.0, "longitude" : locations.last?.coordinate.longitude ?? 0.0]
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(locations.last!, completionHandler:
            {
                placemarks, error -> Void in
                
                // Place details
                guard let placeMark = placemarks?.first else { return }
                
                // Street address
                if let locality = placeMark.locality {
                    self.currLocDetails!["locality"] = locality
                }
                
                if let subLocality = placeMark.subLocality {
                    self.currLocDetails!["subLocality"] = subLocality
                }
                
                if let administrativeArea = placeMark.administrativeArea {
                    self.currLocDetails!["administrativeArea"] = administrativeArea
                }
                
                //print("Final Loc Details: ", self.currLocDetails ?? [:])
                DispatchQueue.main.async { () -> Void in
                    self.delegate.didUpdateTo(location: self.currentLocation!)
                    self.delegate.getCurrLocFull(details: self.currLocDetails!)
                }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedAlways:
            self.delegate.didChangeAuthorizationInLocationSettings(status: ".authAlways")
            print("Auth Always")
        case .authorizedWhenInUse:
            self.delegate.didChangeAuthorizationInLocationSettings(status: ".authWhenInUse")
            print("Auth when in use")
        case .denied:
            self.delegate.didChangeAuthorizationInLocationSettings(status: ".authDenied")
            print("Auth denied")
        case .notDetermined:
            self.delegate.didChangeAuthorizationInLocationSettings(status: ".authDetermined")
            print("Auth not determined")
        case .restricted:
            self.delegate.didChangeAuthorizationInLocationSettings(status: ".authRestricted")
            print("Auth restricted")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER ERROR: ", error.localizedDescription)
        
        self.delegate.didFailWithErrorsWhenReadLocations(errors: error.localizedDescription)
    }
    
}



