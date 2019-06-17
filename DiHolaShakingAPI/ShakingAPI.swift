/*
 * Copyright © 2019 DiHola S.L. All rights reserved.
 */

import CoreLocation
import CoreMotion
import AudioToolbox

public class ShakingAPI {
    
    /*
     * Client API key.
     */
    public var API_KEY = "Get one at www.diholapp.com"
    
    /*
     * User unique identifier in the context of the app.
     */
    public var USER_ID: String!
    
    /*
     * Sensibility for the shaking event.
     */
    public var sensibility = Double(3)
    
    /*
     * Maximum time (in ms) between shaking events
     * to be elegible for pairing.
     */
    public var timingFilter = 2000
    
    /*
     * Maximum distance (in meters)
     * to be elegible for pairing.
     */
    public var distanceFilter = 100
    
    /*
     * Keep searching even if a user has been found.
     * Allows to connect with multiple devices.
     */
    public var keepSearching = false
    
    /*
     * True if the location is provided programatically,
     * otherwise the device location will be used.
     */
    public var manualLocation = false
    
    /*
     * Vibrate on shaking.
     */
    public var vibrate = true
    
    /*
     * Shaking callback (optional).
     */
    public var onShaking: (() -> Void)?
    
    /*
     * Success callback.
     */
    public var onSuccess: (Array<String>) -> Void
    
    /*
     * Error callback.
     */
    public var onError: (ShakingCode) -> Void
    
    /*
     * Server URL.
     */
    private let SERVER_URL = "https://api.diholapplication.com/shaking/connect"
    
    /*
     * Accelerometer subscription.
     */
    private let accelerometer = CMMotionManager()
    
    /*
     * Accelerometer timer.
     */
    private var timer: Timer!
    
    /*
     * Location manager.
     */
    private let locationManager = CLLocationManager()
    
    /*
     * Latitude and longitude coordinates.
     * Note: lat = lng = 0 is an invalid location.
     */
    private var lat = Double(0)
    private var lng = Double(0)
    
    
    /*
     * Last time a shaking event was detected.
     */
    private var lastShaking: TimeInterval?
    
    /*
     * API status.
     */
    private var stopped = true
    private var paused = false
    private var processing = false
    
    
    public init(API_KEY: String,
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
    
    /*
     * Starts listening to shaking events.
     */
    public func start(){
        if(stopped){
            stopped = false;
            paused = false;
            
            self.getLocation();
            self.startAccelerometer();
        }
    }
    
    /*
     * Stops listening to shaking events.
     */
    public func stop(){

        if(!stopped){
            stopped = true;
            paused = false;
            
            self.timer?.invalidate();
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
    
    /*
     * Simulates a shaking event.
     */
    public func simulate(){
        self.vibrateDevice();
        self.onShaking?();
        self.connect();
    }
    
    public func setLocation(latitude: Double, longitude: Double) {
        self.lat = latitude;
        self.lng = longitude;
        self.manualLocation = true;
    }
    
    /*
     * Sends request to the server.
     */
    private func connect(){
        
        self.processing = true;
        
        if(self.lat == 0 && self.lng == 0 && self.manualLocation == false){
            onError(ShakingCode.LOCATION_PERMISSION_ERROR);
        }
        
        let json: [String: Any] = [
            "api_key": self.API_KEY,
            "id": self.USER_ID,
            "lat": self.lat,
            "lng": self.lng,
            "distanceFilter": self.distanceFilter,
            "timingFilter": self.timingFilter,
            "keepSearching": self.keepSearching
        ]
        
        
        // Create POST request
        let url = URL(string: SERVER_URL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Insert JSON data to the request
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: self.handleServerResponse);
        
        task.resume();
    }
    
    
    private func handleServerResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?){
        
        if stopped {
            return;
        }
        
        DispatchQueue.main.async {
            
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
        
        if(self.lastShaking != timestamp && abs(x) + abs(y) + abs(z) >= self.sensibility){
            
            self.lastShaking = timestamp;
            
            self.pause();
            self.vibrateDevice();
            self.onShaking?();
            self.getLocation();
            self.connect();
        }
        
    }
    
    private func vibrateDevice(){
        if self.vibrate {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate));
        }
    }
    
}
