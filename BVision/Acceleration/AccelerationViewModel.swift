//
//  AccelerationViewModel.swift
//  BVision
//
//  Created by gitaeklee on 12/6/22.
//

import Foundation
import CoreLocation
import Combine

class AccelerationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentSpeed: Double = 0.0
    @Published var unitString: String = "MPH"

    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func stopUpdates() {
        self.locationManager.stopUpdatingLocation()
    }
    
    func resumeUpdates() {
        self.locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let metricUnits = UserDefaults.standard.bool(forKey: "metricUnits")
        var speed = location.speed
        
        if speed < 0 {
            speed = 0
        }
        
        if metricUnits == false {
            speed = speed * 2.237
            unitString = "MPH"
        } else {
            speed = speed * 3.6
            unitString = "km/h"
        }
        
        currentSpeed = speed
    }
}
