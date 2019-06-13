/*
 * Copyright © 2019 DiHola S.L. All rights reserved.
 */

import Foundation
import CoreLocation
import CoreMotion
import UIKit
import AudioToolbox

class ShakingAPI {
    
    let SERVER_URL = "https://api.diholapplication.com/shaking/connect"
    
    /*
     * Client API key.
     */
    var API_KEY = "Get one at www.diholapp.com"
    
    /*
     * User unique identifier in the context of the app.
     */
    var USER_ID: String!
    
    /*
     * Latitude and longitude coordinates.
     * Note: lat = lng = 0 is an invalid location.
     */
    var lat = Double(0)
    var lng = Double(0)
    
    /*
     * Sensibility for the shaking event.
     */
    var sensibility = Double(3)
    
    /*
     * Maximum time (in ms) between shaking events
     * to be elegible for pairing.
     */
    var timingFilter = 2000
    
    /*
     * Maximum distance (in meters)
     * to be elegible for pairing.
     */
    var distanceFilter = 100
    
    /*
     * Keep searching even if a user has been found.
     * Allows to connect with multiple devices.
     */
    var keepSearching = false
    
    /*
     * True if the location is provided programatically,
     * otherwise the device location will be used.
     */
    var manualLocation = false
    
    /*
     * Vibrate on shaking.
     */
    var vibrate = true
    
    /*
     * Accelerometer subscription.
     */
    let accelerometer = CMMotionManager()
    
    /*
     * Location manager.
     */
    let locationManager = CLLocationManager()
    
    var timer: Timer!
    
    /*
     * Shaking callback (optional).
     */
    var onShaking: (() -> Void)?
    
    /*
     * Success callback.
     */
    var onSuccess: (Array<String>) -> Void
    
    /*
     * Error callback.
     */
    var onError: (ShakingCode) -> Void
    
    
    /*
     * Last time a shaking event was detected.
     */
    var lastShaking: TimeInterval?
    
    
    /*
     * API status.
     */
    var stopped = true
    var paused = false
    var processing = false
    
    
    init(API_KEY: String,
         USER_ID: String,
         onShaking: (() -> ())? = nil,
         onSuccess: @escaping (Array<String>) -> (),
         onError: @escaping (ShakingCode) -> ())
    {
        
        self.API_KEY = API_KEY;
        self.USER_ID = USER_ID;
        
        self.onShaking = onShaking;
        self.onSuccess = onSuccess;
        self.onError = onError;
        
    }
    
    func start(){
        if(stopped){
            stopped = false;
            paused = false;
            
            self.getLocation();
            self.startAccelerometer();
        }
    }
    
    func stop(){
        if(!stopped){
            stopped = true;
            paused = false;
            
            self.timer.invalidate();
            self.accelerometer.stopAccelerometerUpdates();
        }
    }
    
    private func restart(){
    
        if(!self.stopped && !self.processing && self.paused){
            self.paused = false;
            self.getLocation();
            self.startAccelerometer();
        }
    }
    
    private func pause(){
        if(!self.paused){
            self.paused = true;
            
            self.timer.invalidate();
            self.accelerometer.stopAccelerometerUpdates();
        }
    }
    
    func simulate(){
        self.connect();
    }
    
    func setLocation(lat: Double, lng: Double) -> Self {
        self.lat = lat;
        self.lng = lng;
        self.manualLocation = true;
        return self;
    }
    
    
    private func connect(){
        
        self.processing = true;
        
        if(self.lat == 0 && self.lng == 0 && self.manualLocation == false){
            onError(ShakingCode.LOCATION_PERMISSION_ERROR);
        }
        
        // Prepare JSON data
        let json: [String: Any] = [
            "api_key": self.API_KEY,
            "id": self.USER_ID,
            "lat": self.lat,
            "lng": self.lng,
            "distanceFilter": self.distanceFilter,
            "timingFilter": self.timingFilter,
            "keepSearching": self.keepSearching
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create POST request
        let url = URL(string: SERVER_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Insert JSON data to the request
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: self.handleServerResponse);
        
        task.resume();
    }
    
    private func handleServerResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?){
        
        var serverError = false;
        
        guard let data = data, error == nil else {
            serverError = true;
            self.onError(ShakingCode.SERVER_ERROR);
            return;
        }
        
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseJSON = responseJSON as? [String: Any] {
            
            if let status = responseJSON["status"] as? [String: Any],
               let response = responseJSON["response"] as? Array<String>
            {
                let code = status["code"] as? Int;
                switch code {
                case 200:
                    self.onSuccess(response);
                    break;
                case 401:
                    self.onError(ShakingCode.AUTHENTICATION_ERROR);
                    break;
                case 403:
                    self.onError(ShakingCode.API_KEY_EXPIRED);
                    break;
                default:
                    serverError = true;
                    self.onError(ShakingCode.SERVER_ERROR);
                }
            } else {
                serverError = true;
                self.onError(ShakingCode.SERVER_ERROR);
            }
            
        } else {
            serverError = true;
            self.onError(ShakingCode.SERVER_ERROR);
        }
        
        self.processing = false;
        
        // 2 second delay in case of server error
        DispatchQueue.main.asyncAfter(deadline: .now() + (serverError ? 2.0 : 0.0), execute: {
            self.restart();
        })
    }
    
    private func getLocation(){
        
        if(self.manualLocation) {
            return;
        }
        
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            guard let currentLocation = self.locationManager.location else {
                onError(ShakingCode.LOCATION_DISABLED);
                return
            }
            self.lat = currentLocation.coordinate.latitude;
            self.lng = currentLocation.coordinate.longitude;
            
        } else {
            self.locationManager.requestWhenInUseAuthorization();
        }
    }
    
    
    private func startAccelerometer() {
        // Make sure the accelerometer hardware is available.
        if self.accelerometer.isAccelerometerAvailable {
            self.accelerometer.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
            self.accelerometer.startAccelerometerUpdates()
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(),
                               interval: (1.0/60.0),
                               repeats: true,
                               block: { (timer) in
                                // Get the accelerometer data.
                                if let data = self.accelerometer.accelerometerData {
                                    let x = data.acceleration.x;
                                    let y = data.acceleration.y;
                                    let z = data.acceleration.z;
                                    
                                    let timestamp = data.timestamp;
                                    
                                    self.triggerShakingEvent(x, y, z, timestamp);
                                    
                                } else {
                                    //self.onError(ShakingCode.SENSOR_ERROR);
                                }
                            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
            
        } else {
            onError(ShakingCode.SENSOR_ERROR);
        }
    }
    
    private func triggerShakingEvent(_ x: Double, _ y: Double, _ z: Double,  _ timestamp: TimeInterval){
        if(abs(x) + abs(y) + abs(z) >= self.sensibility){
            
            if(self.lastShaking != timestamp){
                self.lastShaking = timestamp;

                self.pause();
                self.vibrateDevice();
                self.onShaking?();
                self.getLocation();
                self.connect();
            }
        }
    }
    
    private func vibrateDevice(){
        if(self.vibrate){
            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate));
        }
    }
    
}
