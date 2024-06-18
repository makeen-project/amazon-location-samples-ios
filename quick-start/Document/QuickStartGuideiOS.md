### Creating an iOS app

In this section, you will create an iOS application with a map, the ability to search at a location, and use trackers to
track user locations. First, you will create your Amazon Location resources, an Amazon Cognito identity, and an API key
for your application.

### Topics

- [Creating Amazon Location resources for your app](#creating-amazon-location-resources-for-your-app)
- [Setting up authentication for your application](#setting-up-authentication-for-your-application)
- [Creating the base iOS application](#creating-the-base-ios-application)
    - [To create an empty application (Xcode)](#to-create-an-empty-application-xcode)
  - [Installing required app dependencies via Swift Package Manager](#installing-required-app-dependencies-via-swift-package-manager)
    - [Add Maplibre to your project](#add-maplibre-to-your-project)
    - [Add Amazon location authentication SDK iOS to your project](#add-amazon-location-authentication-sdk-ios-to-your-project)
    - [Add Amazon location tracking SDK iOS to your project](#add-amazon-location-tracking-sdk-ios-to-your-project)
  - [Setting up initial code](#setting-up-initial-code)
- [Adding an interactive map to your application](#adding-an-interactive-map-to-your-application)
- [Adding search to your application](#adding-search-to-your-application)
- [Adding tracking to your application](#adding-tracking-to-your-application)
- [Seeing the final application](#seeing-the-final-application)
- [What's next](#whats-next)

## Creating Amazon Location resources for your app

1. If you haven't created an AWS account yet, [please do so](https://portal.aws.amazon.com/billing/signup#/start/email).
   You can generate Amazon Location Service resources once your AWS account is ready. These resources will be essential
   for executing the provided code snippets.
2. Select your preferred map style:
    1. Navigate to the [Maps section](https://console.aws.amazon.com/location/maps/home) in the Amazon Location Service
       console and click 'Create Map' to preview available map styles.
    2. Give the new map resource a Name and Description. Remember the name you assign to this map resource, which will
       be used later in the tutorial.
    3. When choosing a map style, consider the map data provider. Refer to section 82 of
       the [AWS service terms](http://aws.amazon.com/service-terms) for more details.
    4. Accept
       the [Amazon Location Terms and Conditions](https://aws.amazon.com/service-terms/#:~:text=82.%20Amazon%20Location%20Service),
       then click 'Create Map'. After creation, interact with the chosen map by zooming in, out, or panning in any
       direction.
3. Select the place index you wish to utilize:
    1. Navigate to the [Place indexes page](https://us-east-1.console.aws.amazon.com/location/places/home) within the
       Amazon Location Service console and click 'Create Place Index'.
    2. Provide a Name and Description for the new place index resource. Remember the name you assign to this place index
       resource, which will be used later in the tutorial.
    3. Select a data provider, ideally aligning with your chosen map provider, to ensure search compatibility with the
       maps. Refer to section 82 of the [AWS service terms](http://aws.amazon.com/service-terms) for more details.
    4. Choose the Data storage option. As no data is stored for this tutorial, select 'No, single use only'.
    5. Accept
       the [Amazon Location Terms and Conditions](https://aws.amazon.com/service-terms/#:~:text=82.%20Amazon%20Location%20Service)
       and then click 'Create Place Index'.
4. Select the tracker you wish to utilize:
    1. Navigate to the [Trackers page](https://us-east-1.console.aws.amazon.com/location/tracking/home) within the
       Amazon Location Service console and click 'Create tracker'.
    2. Provide a Name and Description for the new tracker resource. Remember the name you assign to this tracker
       resource, which will be used later in the tutorial.
    3. Select one of the position filtering options. Refer to
       the [Tracker developer guide](https://docs.aws.amazon.com/location/latest/developerguide/start-tracking.html) for
       more details.
    4. Click 'Create tracker'.

## Setting up authentication for your application

The application that you create in this tutorial has anonymous usage, meaning that your users are not required to sign
into AWS to use the application. However, the Amazon Location Service APIs require authentication to use. You can use
either API keys or Amazon Cognito to provide authentication and authorization for anonymous users. This tutorial will
use Amazon Cognito. Before you can use Amazon Cognito in your application, you must create an Amazon Cognito identity
pool.

**Create an IAM policy**

1. Sign in to the IAM console at https://console.aws.amazon.com/iam/ with your user that has administrator permissions.
2. In the navigation pane, choose Policies.
3. In the content pane, choose Create policy.
4. Choose the JSON option and copy the text from the following JSON policy document. Paste this text into the JSON text
   box.

    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "geo:GetMapTile",
                    "geo:GetMapStyleDescriptor",
                    "geo:GetMapSprites",
                    "geo:GetMapGlyphs",
                    "geo:SearchPlaceIndexForPosition",
                    "geo:GetDevicePositionHistory",
                    "geo:BatchUpdateDevicePosition"
                ],
                "Resource": [
                    "arn:aws:geo:{Region}:{Account}:map/{MapName}",
                    "arn:aws:geo:{Region}:{Account}:place-index/{IndexName}",
                    "arn:aws:geo:{Region}:{Account}:tracker/{TrackerName}"
                ]
            }
        ]
    }
    ```

This is a policy example for Tracking. To use the example for your own policy, replace the `Region`, `Account`, `MapName`, `IndexName` and `TrackerName` placeholders.

---
**Note**

While unauthenticated identity pools are intended for exposure on unsecured internet sites, note that they will be
exchanged for standard, time-limited AWS credentials.

It's important to scope the IAM roles associated with unauthenticated identity pools appropriately. For more information
about using and appropriately scoping policies in Amazon Cognito with Amazon Location
Service, [see Granting access to Amazon Location Service](https://docs.aws.amazon.com/location/latest/developerguide/how-to-access.html).

---

---
**Note**

You can switch between the **Visual** and **JSON** editor options anytime. However, if you make changes or choose **Review policy** in the **Visual** editor tab, IAM might restructure your policy to optimize it for the Visual editor.

---

5. On the Review and Create page, provide a name for the policy name field. Review the permissions granted by your
   policy, and then choose Create Policy to save your work.

The new policy appears in the list of managed policies and is ready to attach.

**Set up authentication for your tracking**

1. Set up authentication for your map application in
   the [Amazon Cognito console](https://console.aws.amazon.com/cognito/home/).
2. Open the **Identity pools** page.

---
**Important**

The pool that you create must be in the same AWS account and AWS Region as the Amazon Location Service resources that
you created in the previous section.

---

3. Choose **Create Identity pool**.
4. Starting with the **Configure identity pool trust** step. For user access authentication, select **Guest access**,
   and press next.
5. On the **Configure permissions** page select the **Use an existing IAM role** and enter the name of the IAM role you
   created in the previous step. When ready press next to move on to the next step.
6. On the **Configure properties** page, provide a name for your identity pool. Then press **Next**.
7. On the **Review and create** page, review all the information present then press **Create identity pool**.
8. Open the **Identity pools** page, and select the identity pool you just created. Then copy or write down the
   IdentityPoolId that you will use later in your browser script.

## Creating the base iOS application

In this tutorial, you will create an iOS application that embeds a map and allows the user to find what's at a location
on the map.

First, let's create a Swift application using Xcode's new project wizard.

#### To create an empty application (Xcode)

- Start Xcode. On the menu, choose File, New Project.
- From the iOS tab, select App, and then choose Next.
- Choose a Product Name, Organization Identifier, `SwiftUI` in the `Interface` field, and then choose Next for your
  application.
- Select the location where you want to save your project and click Create.
- Next, you will add the map control to the application.

### Installing required app dependencies via Swift Package Manager

#### Add Maplibre to your project

- In Xcode, right-click the project and click `Add Packages....` This will open the Packages window, which gives you
  access to the Swift packages.
- In the Packages window, type Maplibre Native package
  URL: <https://github.com/maplibre/maplibre-gl-native-distribution> and press Enter.
- Select the `maplibre-gl-native-distribution` package and click on the Add Package button.
- Select the `Mapbox` product and click on the Add Package button.

#### Add Amazon location authentication SDK iOS to your project

- In the Packages window, type Amazon location authentication SDK iOS
  URL: <https://github.com/aws-geospatial/amazon-location-mobile-auth-sdk-ios> and press Enter.
- Select the `amazon-location-mobile-auth-sdk-ios` package and click on the Add Package button.
- Select the `AmazonLocationiOSAuthSDK` product and click on the Add Package button.

#### Add Amazon location tracking SDK iOS to your project

- In the Packages window, type Amazon location authentication SDK iOS
  URL: <https://github.com/aws-geospatial/amazon-location-mobile-tracking-sdk-ios> and press Enter.
- Select the `amazon-location-mobile-tracking-sdk-ios` package and click on the Add Package button.
- Select the `AmazonLocationiOSTrackingSDK` product and click on the Add Package button.

### Setting up initial code

**Enable Location permissions in your app**

To add location permissions in an iOS project using Xcode, you need to follow these general steps:

- Open your Xcode project.
- Locate the Info.plist file.
- Add the necessary keys for location permissions based on your app's requirements. Here are the keys:
    - NSLocationWhenInUseUsageDescription: Description of why your app needs location access when it's in use.
    - NSLocationAlwaysAndWhenInUseUsageDescription: Description of why your app needs continuous location access.

**Configure resource values in your app**

Add a new file named `Config.xcconfig` and fill out the values that you had created previously in the Amazon console.

```
REGION =
INDEX_NAME =
MAP_NAME =
IDENTITY_POOL_ID =
TRACKER_NAME =
```

- From the left side navigator section, select the project.
- Under the targets section, select your app and click on the info tab.
- Add info properties with values like the below:
  ![alt text](images/info-config.png)
- Add `Config.swift` file with the contents below, which will read config values from the Bundle info file

```
import Foundation

enum Config {
    static let region = Bundle.main.object(forInfoDictionaryKey: "Region") as! String
    static let mapName = Bundle.main.object(forInfoDictionaryKey: "MapName") as! String
    static let indexName = Bundle.main.object(forInfoDictionaryKey: "IndexName") as! String
    static let identityPoolId = Bundle.main.object(forInfoDictionaryKey: "IdentityPoolId") as! String
    static let trackerName = Bundle.main.object(forInfoDictionaryKey: "TrackerName") as! String
}
```

- Create a new folder with the name `ViewModel` and Add a `TrackingViewModel.swift` file inside it

```
import SwiftUI
import AmazonLocationiOSAuthSDK
import MapLibre

final class TrackingViewModel : ObservableObject {
    @Published var trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
    @Published var trackingButtonColor = Color.blue
    @Published var trackingButtonIcon = "play.circle"
    @Published var region : String
    @Published var mapName : String
    @Published var indexName : String
    @Published var identityPoolId : String
    @Published var trackerName : String
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var centerLabel = ""

    var clientIntialised: Bool
    var client: LocationTracker!
    var authHelper: AuthHelper
    var credentialsProvider: LocationCredentialsProvider?
    var mlnMapView: MLNMapView?
    var mapViewDelegate: MapViewDelegate?
    var lastGetTrackingTime: Date?
    var trackingActive: Bool
    
    init(region: String, mapName: String, indexName: String, identityPoolId: String, trackerName: String) {
        self.region = region
        self.mapName = mapName
        self.indexName = indexName
        self.identityPoolId = identityPoolId
        self.trackerName = trackerName
        self.authHelper = AuthHelper()
        self.trackingActive = false
        self.clientIntialised = false
    }
    
    func authWithCognito(identityPoolId: String?) {
        guard let identityPoolId = identityPoolId?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            alertTitle = NSLocalizedString("Error", comment: "")
            alertMessage = NSLocalizedString("NotAllFieldsAreConfigured", comment: "")
            showAlert = true
            return
        }
        credentialsProvider = authHelper.authenticateWithCognitoUserPool(identityPoolId: identityPoolId)
        initializeClient()
    }
    
    func initializeClient() {
        client = LocationTracker(provider: credentialsProvider!, trackerName: trackerName)
        clientIntialised = true
    }
}
```

## Adding an interactive map to your application

In this section, you will add the map control to your application. This tutorial uses MapLibre and the AWS API for
managing the map view in the application. The map control itself is part of
the <a href="https://docs.maptiler.com/maplibre-gl-native-ios/">MapLibre GL Native iOS</a> library.

- Add `MapView.swift` file under the `Views` folder with the following code:

```
import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {
    var onMapViewAvailable: ((MLNMapView) -> Void)?
    var mlnMapView: MLNMapView?
    var trackingViewModel: TrackingViewModel
    
    func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(self, trackingViewModel: trackingViewModel)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = URL(string: "https://maps.geo.\(trackingViewModel.region).amazonaws.com/maps/v0/maps/\(trackingViewModel.mapName)/style-descriptor")
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setZoomLevel(15, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        context.coordinator.mlnMapView = mapView
        mapView.delegate = context.coordinator

        mapView.logoView.isHidden = true
        context.coordinator.addCenterMarker()
        
        onMapViewAvailable?(mapView)
        trackingViewModel.mlnMapView = mapView
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate, MapViewDelegate {
        var control: MapView
        var mlnMapView: MLNMapView?
        var trackingViewModel: TrackingViewModel
        var centerMarker: MLNPointAnnotation?
        
        public init(_ control: MapView, trackingViewModel: TrackingViewModel) {
            self.control = control
            self.trackingViewModel = trackingViewModel
            super.init()
            self.trackingViewModel.mapViewDelegate = self
        }

        func mapViewDidFinishRenderingMap(_ mapView: MLNMapView, fullyRendered: Bool) {
            if(fullyRendered) {
                mapView.accessibilityIdentifier = "MapView"
                mapView.isAccessibilityElement = false
            }
        }
        
        func addCenterMarker() {
            guard let mlnMapView = mlnMapView else {
                return
            }

            let centerCoordinate = mlnMapView.centerCoordinate
            let marker = MLNPointAnnotation()
            marker.coordinate = centerCoordinate
            marker.accessibilityLabel = "CenterMarker"
            mlnMapView.addAnnotation(marker)
            centerMarker = marker

            trackingViewModel.reverseGeocodeCenter(centerCoordinate: centerCoordinate, marker: marker)
        }
        
        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            if let marker = centerMarker {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    mapView.deselectAnnotation(marker, animated: false)
                    marker.coordinate = mapView.centerCoordinate
                    let centerCoordinate = mapView.centerCoordinate
                    self.trackingViewModel.reverseGeocodeCenter(centerCoordinate: centerCoordinate, marker: marker)
                }
            }
        }
    }
}
```

- Add `AWSSignatureV4Delegate` file under the `ViewModel` folder. This file is used to sign with all the MapView http requests to render the map:

```
import MapLibre
import AmazonLocationiOSAuthSDK
 
class AWSSignatureV4Delegate : NSObject, MLNOfflineStorageDelegate {
    private let awsSigner: AWSSigner
  
    init(credentialsProvider: LocationCredentialsProvider) {
        self.awsSigner = AWSSigner(amazonLocationCognitoCredentialsProvider: credentialsProvider.getCognitoProvider()!, serviceName: "geo")
        super.init()
    }
 
    func offlineStorage(_ storage: MLNOfflineStorage, urlForResourceOf kind: MLNResourceKind, with url: URL) -> URL {
        if url.host?.contains("amazonaws.com") != true {
            return url
        }
        let signedURL = awsSigner.signURL(url: url, expires: .hours(1))
        
        return signedURL
    }
}
```

- Add `UserLocationView.swift` file under `Views` folder. This view will show a button which center the map to the
  user's location

```
import SwiftUI

struct UserLocationView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
            Button(action: {
                trackingViewModel.locateMe()
            }) {
                Image(systemName: "scope")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(5)
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .accessibility(identifier: "LocateMeButton")
            .padding(.trailing, 10)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
```

- Add `TrackingView.swift` file with the following code:

```
import SwiftUI

struct TrackingView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(trackingViewModel: trackingViewModel)
            VStack {
                UserLocationView(trackingViewModel: trackingViewModel)
            }
        }
        .onAppear() {
            if !trackingViewModel.identityPoolId.isEmpty {
                trackingViewModel.authWithCognito(identityPoolId: trackingViewModel.identityPoolId)
            }
        }
    }
}
```

You can now build the application. To run it, you may have to set up a device to emulate it in Xcode or use the app on
your device. Use this app to see how the map control behaves. You can pan by dragging on the map and pinch to zoom. On
your own, you can change how the map control works to customize it to the needs of your application.

In the next section, you will add a marker on the map, and show the address of the location where the marker is as you
move the map.

## Adding search to your application

This section defines how to add searching on the map. In this case, you will add a reverse geocoding search, where you
find the items at a location. To simplify the use of an iOS app, we will search the center of the screen. To find a new
location, move the map to where you want to search. We will place a marker at the center of the map to show where we are
searching.

- Add the following code in `TrackingViewModel.swift` file which is related to the reverse geocoding search

```
func reverseGeocodeCenter(centerCoordinate: CLLocationCoordinate2D, marker: MLNPointAnnotation) {
    let position = [NSNumber(value: centerCoordinate.longitude), NSNumber(value: centerCoordinate.latitude)]
    searchPositionAPI(position: position, marker: marker)
}

func searchPositionAPI(position: [Double], marker: MLNPointAnnotation) {
    if let amazonClient = authHelper.getLocationClient() {
        Task {
            let searchRequest = SearchPlaceIndexForPositionInput(indexName: indexName, language: "en" , maxResults: 10, position: position)
            let searchResponse = try? await amazonClient.searchPosition(indexName: indexName, input: searchRequest)
            DispatchQueue.main.async {
                self.centerLabel = searchResponse?.results?.first?.place?.label ?? ""
                self.mlnMapView?.selectAnnotation(marker, animated: true, completionHandler: {})
            }
        }
    }
}
```

- Update `TrackingView.swift` file with the following code which will show the mapview's centered location's address

```
import SwiftUI

struct TrackingView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            if trackingViewModel.mapSigningIntialised {
                MapView(trackingViewModel: trackingViewModel)
                VStack {
                    UserLocationView(trackingViewModel: trackingViewModel)
                    CenterAddressView(trackingViewModel: trackingViewModel)
                }
            }
            else {
                Text("Loading...") 
            }
        }
        .onAppear() {
            if !trackingViewModel.identityPoolId.isEmpty {
                Task {
                    do {
                        try await trackingViewModel.authWithCognito(identityPoolId: trackingViewModel.identityPoolId)
                    }
                    catch {
                        print(error)
                    }
                }
            }
        }
    }
}
```

## Adding tracking to your application

The last step for your application is to add tracking functionality to your app. In this case, you will add start
tracking, stop tracking, fetch and display tracker points on your app.

- Add `TrackingBottomView.swift` file in your project. Which has a button that starts and stops tracking user locations
  and shows tracking points on the map.

```
import SwiftUI

struct TrackingBottomView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
           Button(action: {
               Task {
                   if(trackingViewModel.trackingButtonText == NSLocalizedString("StartTrackingLabel", comment: "")) {
                       trackingViewModel.startTracking()
                   } else {
                       trackingViewModel.stopTracking()
                   }
               }
           }) {
               HStack {
                   Spacer()
                   Text("Tracking")
                       .foregroundColor(trackingViewModel.trackingButtonColor)
                       .background(.white)
                       .cornerRadius(15.0)
                   
                   Image(systemName: trackingViewModel.trackingButtonIcon)
                       .resizable()
                       .frame(width: 24, height: 24)
                       .padding(5)
                       .background(.white)
                       .foregroundColor(trackingViewModel.trackingButtonColor)

               }
           }
           .accessibility(identifier: "TrackingButton")
           .background(.white)
           .clipShape(RoundedRectangle(cornerRadius: 8))
           .padding(.trailing, 10)
           .padding(.bottom, 40)
           .frame(width: 130, alignment: .trailing)
           .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)
       }
}
```

- Update `TrackingView.swift` file with the following code

```
import SwiftUI

struct TrackingView: View {
    @ObservedObject var trackingViewModel: TrackingViewModel
    var body: some View {
        ZStack(alignment: .bottom) {
            if trackingViewModel.mapSigningIntialised {
                MapView(trackingViewModel: trackingViewModel)
                VStack {
                    UserLocationView(trackingViewModel: trackingViewModel)
                    CenterAddressView(trackingViewModel: trackingViewModel)
                    TrackingBottomView(trackingViewModel: trackingViewModel)
                }
            }
            else {
                Text("Loading...") 
            }
        }
        .onAppear() {
            if !trackingViewModel.identityPoolId.isEmpty {
                Task {
                    do {
                        try await trackingViewModel.authWithCognito(identityPoolId: trackingViewModel.identityPoolId)
                    }
                    catch {
                        print(error)
                    }
                }
            }
        }
    }
}
```

- Add the following code in `TrackingViewModel.swift` file. These functions are responsible for start and stop tracking.
  It will also show an error alert if user location permission is denied.

- Implement foreground tracking
  To start tracking in the foreground, see the following code example:

```
    func showLocationDeniedRationale() {
        alertTitle = NSLocalizedString("locationManagerAlertTitle", comment: "")
        alertMessage = NSLocalizedString("locationManagerAlertText", comment: "")
        showAlert = true
    }
    
    // Required in info.plist: Privacy - Location When In Use Usage Description
    func startTracking() {
        do {
            print("Tracking Started...")
            if(client == nil) {
                initializeClient()
            }
            try client.startTracking()
            DispatchQueue.main.async { [self] in
                self.trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
                self.trackingButtonColor = .red
                self.trackingButtonIcon = "pause.circle"
                trackingActive = true
            }
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking")
        }
    }
    
    func stopTracking() {
        print("Tracking Stopped...")
        client.stopTracking()
        trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
        trackingButtonColor = .blue
        trackingButtonIcon = "play.circle"
        trackingActive = false
    }
```

---
**Note**

The `startTracking` will ask for the user's location permission. The application must use "When In Use" or "Only Once"
permissions. Otherwise, the application will throw a permission denied error.

---

- **Get and display tracking locations**
  To get the locations from the user's device, you need to provide the start and end date and time. A single call
  returns a maximum of 100 tracking locations, but if there are more than 100 tracking locations, it will return
  a `nextToken` value. You will need to call subsequent `getTrackerDeviceLocation` calls with `nextToken` to load more
  tracking points for the given start and end time.

```
    func getTrackingPoints(nextToken: String? = nil) async throws {
        guard trackingActive else {
            return
        }
        // Initialize startTime to 24 hours ago from the current date and time.
        let startTime: Date = Date().addingTimeInterval(-86400)
        var endTime: Date = Date()
        if lastGetTrackingTime != nil {
            endTime = lastGetTrackingTime!
        }
        let result = try await client?.getTrackerDeviceLocation(nextToken: nextToken, startTime: startTime, endTime: endTime)
        if let trackingData = result {
            
            lastGetTrackingTime = Date()
            let devicePositions = trackingData.devicePositions

            let positions = devicePositions!.sorted { (pos1: LocationClientTypes.DevicePosition, pos2: LocationClientTypes.DevicePosition) -> Bool in
                guard let date1 = pos1.sampleTime,
                      let date2 = pos2.sampleTime else {
                    return false
                }
                return date1 < date2
            }

            let trackingPoints = positions.compactMap { position -> CLLocationCoordinate2D? in
                guard let latitude = position.position!.last, let longitude = position.position!.first else {
                    return nil
                }
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            DispatchQueue.main.async {
                self.mapViewDelegate!.drawTrackingPoints( trackingPoints: trackingPoints)
            }
            if let nextToken = trackingData.nextToken {
                try await getTrackingPoints(nextToken: nextToken)
            }
        }
    }
```

- Now replace `MapView.swift` file with the following code:

```
import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {
    var onMapViewAvailable: ((MLNMapView) -> Void)?
    var mlnMapView: MLNMapView?
    var trackingViewModel: TrackingViewModel
    
    func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(self, trackingViewModel: trackingViewModel)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = URL(string: "https://maps.geo.\(trackingViewModel.region).amazonaws.com/maps/v0/maps/\(trackingViewModel.mapName)/style-descriptor")
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setZoomLevel(15, animated: true)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        context.coordinator.mlnMapView = mapView
        mapView.delegate = context.coordinator

        mapView.logoView.isHidden = true
        context.coordinator.addCenterMarker()
        
        onMapViewAvailable?(mapView)
        trackingViewModel.mlnMapView = mapView
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate, MapViewDelegate {
        var control: MapView
        var mlnMapView: MLNMapView?
        var trackingViewModel: TrackingViewModel
        var centerMarker: MLNPointAnnotation?
        
        public init(_ control: MapView, trackingViewModel: TrackingViewModel) {
            self.control = control
            self.trackingViewModel = trackingViewModel
            super.init()
            self.trackingViewModel.mapViewDelegate = self
        }

        func mapViewDidFinishRenderingMap(_ mapView: MLNMapView, fullyRendered: Bool) {
            if(fullyRendered) {
                mapView.accessibilityIdentifier = "MapView"
                mapView.isAccessibilityElement = false
            }
        }
        
        func addCenterMarker() {
            guard let mlnMapView = mlnMapView else {
                return
            }

            let centerCoordinate = mlnMapView.centerCoordinate
            let marker = MLNPointAnnotation()
            marker.coordinate = centerCoordinate
            marker.accessibilityLabel = "CenterMarker"
            mlnMapView.addAnnotation(marker)
            centerMarker = marker

            trackingViewModel.reverseGeocodeCenter(centerCoordinate: centerCoordinate, marker: marker)
        }
        
        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            if let marker = centerMarker {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    mapView.deselectAnnotation(marker, animated: false)
                    marker.coordinate = mapView.centerCoordinate
                    let centerCoordinate = mapView.centerCoordinate
                    self.trackingViewModel.reverseGeocodeCenter(centerCoordinate: centerCoordinate, marker: marker)
                }
            }
        }
        
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            guard let pointAnnotation = annotation as? MLNPointAnnotation else {
                return nil
            }

            let reuseIdentifier: String
            var color: UIColor = .black
            if pointAnnotation.accessibilityLabel == "Tracking" {
                reuseIdentifier = "TrackingAnnotation"
                color = UIColor(red: 0.00784313725, green: 0.50588235294, blue: 0.58039215686, alpha: 1)
            } else if pointAnnotation.accessibilityLabel == "LocationChange" {
                reuseIdentifier = "LocationChange"
                color = .gray
            } else {
                reuseIdentifier = "DefaultAnnotationView"
            }

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                if reuseIdentifier != "DefaultAnnotationView" {
                    annotationView = MLNAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                    //If point annotation is an uploaded Tracking point the radius is 20 and color is blue, otherwise radius is 10 and color is gray
                    let radius = pointAnnotation.accessibilityLabel == "Tracking" ? 20:10
                    annotationView?.frame = CGRect(x: 0, y: 0, width: radius, height: radius)
                    annotationView?.backgroundColor = color
                    annotationView?.layer.cornerRadius = 10
                    
                    if pointAnnotation.accessibilityLabel == "Tracking" {
                        annotationView?.layer.borderColor = UIColor.white.cgColor
                        annotationView?.layer.borderWidth = 2.0
                        annotationView?.layer.shadowColor = UIColor.black.cgColor
                        annotationView?.layer.shadowOffset = CGSize(width: 0, height: 2)
                        annotationView?.layer.shadowRadius = 3
                        annotationView?.layer.shadowOpacity = 0.2
                        annotationView?.clipsToBounds = false
                    }
                }
                else {
                    return nil
                }
            }

            return annotationView
        }
        
        func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
            if (userLocation?.location) != nil {
                if trackingViewModel.trackingActive {
                    let point = MLNPointAnnotation()
                    point.coordinate = (userLocation?.location!.coordinate)!
                    point.accessibilityLabel = "LocationChange"
                    mapView.addAnnotation(point)
                    Task {
                        do {
                            try await trackingViewModel.getTrackingPoints()
                        }
                        catch {
                            print(error)
                        }
                    }
                }
            }
        }
        
        func checkIfTrackingAnnotationExists(on mapView: MLNMapView, at coordinates: CLLocationCoordinate2D) -> Bool {
            let existingAnnotation = mapView.annotations?.first(where: { annotation in
                guard let annotation = annotation as? MLNPointAnnotation else { return false }
                return annotation.coordinate.latitude == coordinates.latitude &&
                annotation.coordinate.longitude == coordinates.longitude && annotation.accessibilityLabel == "Tracking" })
            return existingAnnotation != nil
        }
        
        public func drawTrackingPoints(trackingPoints: [CLLocationCoordinate2D]?) {
            guard let mapView = mlnMapView, let newTrackingPoints = trackingPoints, !newTrackingPoints.isEmpty else {
                return
            }

            let uniqueCoordinates = newTrackingPoints.filter { coordinate in
                !checkIfTrackingAnnotationExists(on: mapView, at: coordinate)
            }

            let points = uniqueCoordinates.map { coordinate -> MLNPointAnnotation in
                let point = MLNPointAnnotation()
                point.coordinate = coordinate
                point.accessibilityLabel = "Tracking"
                return point
            }
            mapView.addAnnotations(points)
        }
    }
}

protocol MapViewDelegate: AnyObject {
    func drawTrackingPoints(trackingPoints: [CLLocationCoordinate2D]?)
}
```

**Localize String values**

- Add a new file `Localizable.xcstrings`
- Right-click on the `Localizable.xcstrings` file and open it as `Source Code`.
- Replace its content with the following:

```
{
  "sourceLanguage" : "en",
  "strings" : {
    "Cancel" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Cancel"
          }
        }
      }
    },
    "Error" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Error"
          }
        }
      }
    },
    "Loading..." : {

    },
    "locationManagerAlertText" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Allow \\\"Quick Start App\\\" to use your location"
          }
        }
      }
    },
    "locationManagerAlertTitle" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "We need your location to detect your location in map"
          }
        }
      }
    },
    "NotAllFieldsAreConfigured" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Not all the fields are configured"
          }
        }
      }
    },
    "OK" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "OK"
          }
        }
      }
    },
    "StartTrackingLabel" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Start Tracking"
          }
        }
      }
    },
    "StopTrackingLabel" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Stop Tracking"
          }
        }
      }
    },
    "Tracking" : {

    }
  },
  "version" : "1.0"
}
```

- Save your files, and build and run your app to preview the functionality.
- Allow the location permission and tap on the tracking button. The app will start uploading user locations and upload
  them to the Amazon Location tracker. It will also show user location changes, tracking points, and current address on
  the map.

![Tracking View](images/tracking-view.png)

Your quick-start application is complete. This tutorial has shown you how to create an iOS application that:

- Creates a map that users can interact with.
- Handles several map events associated with the user changing the map view.
- Calls an Amazon Location Service API, specifically to search the map at a location, using Amazon Location's
  searchByPosition API.

## Seeing the final application

The final project and source code for this application is available on <a href="https://github.com/aws-geospatial/amazon-location-mobile-quickstart-ios">GitHub</a>.

## What's next

You have completed the quick start tutorial and should have an idea of how Amazon Location Service is used to build iOS applications. To get more out of Amazon Location Service, you can check out the following resources:

Dive deeper into the <a href="https://docs.aws.amazon.com/location/latest/developerguide/how-it-works.html">concepts of Amazon Location Service</a>

Get more information about <a href="https://docs.aws.amazon.com/location/latest/developerguide/using-amazon-location.html">how to use Amazon Location features and functionality</a>

See how to expand on this sample and build more complex applications by looking at <a href="https://docs.aws.amazon.com/location/latest/developerguide/samples.html">code examples using Amazon
Location</a>