# DiHola Shaking API for iOS

DiHola Shaking API makes it easy to build fast and reliable ways to communicate between devices, just by shaking them.
We provide such a secure and flexible protocol that this technology can be applied in any form of data exchange: Payment processing, file sharing, social networking, verification processes, etc.

## Index
1. [Installation](#installation)
2. [Usage](#usage)
3. [Customizing the API](#customizing-the-api)
4. [Methods](#methods)
5. [Error Codes](#error-codes)


Installation
-------

#### CocoaPods

Add the following lines to your `Podfile`:

```ruby
target 'YourProject' do
    use_frameworks!
    pod 'DiHolaShakingAPI', '~> 0.1.4'
end
```

Then run the following command

```bash
$ pod install
```


#### Manual

* Drag DiHolaShakingAPI.xcodeproj to your project in the Project Navigator.
* Select your project and then your app target. Open the Build Phases panel.
* Expand the Target Dependencies group, and add DiHolaShakingAPI framework.


    
Usage
-------

Add `NSLocationWhenInUseUsageDescription` to `Info.plist`

```swift
import DiHolaShakingAPI

var shakingAPI = ShakingAPI(
            
    API_KEY: "Get one at www.diholapp.com",
    USER_ID: "USER_ID",
    
    onShaking: {
        print("Shaking detected")
    },
    
    onSuccess: { (result) in
        print(result)
    },
    
    onError: { (error) in
        print(error)
    }
)
        
shakingAPI.start()
```

Customizing the API
-------

There are different parameters that can be customized as needed:

| Name | Type | Default | Description |
| -- | -- | -- |  -- |
| sensibility | `Double` | `3` |  Sensibility for the shaking event to be triggered.
| distanceFilter | `Int` | `100` | Maximum distance (in meters) between two devices to be eligible for pairing. GPS margin error must be taken into account
| timingFilter | `Int` | `2000` |  Maximum time difference (in milliseconds) between two shaking events to be eligible for pairing. Value between 100 and 10000.
| keepSearching | `Bool` | `false` |  A positive value would allow to keep searching even though if a user has been found. This could allow to pair with multiple devices. The response time will be affected by the timingFilter value.
| vibrate | `Bool` | `true` | Vibrate on shaking.

Example:

```swift
shakingAPI.sensibility = 5
shakingAPI.timingFilter = 4000
shakingAPI.keepSearching = true
```


Methods
-------

### Summary

* [`ShakingAPI`](#ShakingAPI)
* [`start`](#start)
* [`stop`](#stop)
* [`simulate`](#simulate)
* [`setLocation`](#setlocation)



### Details

#### `ShakingAPI()`

```swift
var shakingAPI = ShakingAPI(API_KEY, USER_ID, onShaking, onSuccess, onError);
```
 - **options**:

    | Name | Type | Default | Required | Description |
    | -- | -- | -- | -- | -- |
    | API_KEY | `String` | -- | `yes` | Get one at www.diholapp.com |
    | USER_ID | `String` | -- | `yes` | User identifier |
    | onShaking | `function` | -- | `no` | Invoked when the shaking event is detected
    | onSuccess | `function` | -- | `yes` | Invoked with a list of paired users
    | onError | `function` | -- | `yes` | Invoked whenever an error is encountered


---


    

#### `start()`

```swift
shakingAPI.start();
```

Starts listening to shaking events.


---

#### `stop()`

```swift
shakingAPI.stop();
```

Stops listening to shaking events.

---

#### `simulate()`

```swift
shakingAPI.simulate();
```

Simulates the shaking event.


---

#### `setLocation()`


```swift
shakingAPI.setLocation(latitude, longitude);
```

Setting the location manually will disable using the device location.

**Parameters:**

| Name        | Type     | Default  |
| ----------- | -------- | -------- |
| latitude    | Double   | Device current value|
| longitude   | Double   | Device current value|



Error Codes
----------

| Name                     |  Description|
| ---------------------    |  -------- |
| LOCATION_PERMISSION_ERROR| Location permission has not been accepted|
| LOCATION_DISABLED        | Location is disabled|
| SENSOR_ERROR             | The sensor devices are not available |
| AUTHENTICATION_ERROR     | API key invalid|
| API_KEY_EXPIRED          | API key expired|
| SERVER_ERROR             | Server is not available|
  
Example:

```swift
var shakingAPI = ShakingAPI(

  ...
      
  onError: { (error) in

    switch error {
        case .LOCATION_PERMISSION_ERROR:
            // Do something
            break;
        case .LOCATION_DISABLED:
            // Do something
            break;
        case .AUTHENTICATION_ERROR:
            // Do something
            break;
        case .API_KEY_EXPIRED:
            // Do something
            break;
        case .SERVER_ERROR:
            // Do something
            break;
        case .SENSOR_ERROR:
            // Do something
            break;
    }
  }
);
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
