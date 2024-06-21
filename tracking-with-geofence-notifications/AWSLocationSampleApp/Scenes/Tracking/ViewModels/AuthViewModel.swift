import Foundation
import SwiftUI
import AmazonLocationiOSAuthSDK
import AmazonLocationiOSTrackingSDK
import CoreLocation
import MapLibre
import AWSIoT
import AWSIoTEvents
import AWSIoTEventsData
import AWSIoTAnalytics
import AWSLocation

final class AuthViewModel : ObservableObject {
    @Published var trackingButtonText: String
    @Published var trackingButtonColor = Color.blue
    @Published var trackingButtonIcon = "play.circle"
    @Published var identityPoolId : String
    @Published var mapName : String
    @Published var trackerName : String
    @Published var geofenceCollectionArn : String
    @Published var websocketUrl : String
    @Published var showAlert = false
    @Published var alertTitle = "Title"
    @Published var alertMessage = "Message"
    @Published var showingCognitoConfiguration = false
    
    @Published var timeFilter = false
    @Published var distanceFilter = false
    @Published var accuracyFilter = false
    
    @Published var timeInterval: Double = 30
    @Published var distanceInterval: Double = 30
    
    @Published var clientIntialised: Bool = false
    @Published var mapSigningIntialised: Bool = false
    
    var loginDelegate: LoginViewModelOutputDelegate?
    var client:LocationTracker!
    var signingDelegate: MLNOfflineStorageDelegate?
    var currentLocation: CLLocation!
    
    //private var iotDataManager: AWSIoTDataManager?
    //private var iotManager: AWSIoTManager?
    private var iot: AWSIoT.IoTClient? = nil
    var iotPublisher: Optional<AWSIoT.IoTClient>.Publisher? = nil
    //var cancellables = Set<AWSIoT.IoTClient>.()
    
    var authHelper: AuthHelper
    var credentialsProvider: LocationCredentialsProvider?
    
    func populateFilterValues() {
        guard let config = client?.getTrackerConfig() else {
            return
        }
        DispatchQueue.main.async { [self] in
            let filters = config.locationFilters
            timeFilter = filters.contains { $0 is TimeLocationFilter }
            distanceFilter = filters.contains { $0 is DistanceLocationFilter }
            accuracyFilter = filters.contains { $0 is AccuracyLocationFilter }
            
            timeInterval = config.trackingTimeInterval
            distanceInterval = config.trackingDistanceInterval
        }
    }
    
    init(identityPoolId: String, mapName: String, trackerName: String, geofenceCollectionArn: String, websocketUrl: String) {
        self.identityPoolId = identityPoolId
        self.mapName = mapName
        self.trackerName = trackerName
        self.geofenceCollectionArn = geofenceCollectionArn
        self.websocketUrl = websocketUrl
        self.authHelper = AuthHelper()
        self.iot = nil
        self.trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
    }
    
    func authWithCognito(identityPoolId: String?) async throws {
        
        guard let identityPoolId = identityPoolId?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            DispatchQueue.main.async { [self] in
                let model = AlertModel(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("NotAllFieldsAreConfigured", comment: ""), okButton: NSLocalizedString("Ok", comment: ""))
                loginDelegate?.showAlert(model)
            }
            return
        }
        credentialsProvider = try await authHelper.authenticateWithCognitoIdentityPool(identityPoolId: identityPoolId)
        initializeClient()
        
        mapViewSigning()
        
        populateFilterValues()
    }
    
    func mapViewSigning() {
        DispatchQueue.main.async { [self] in
            signingDelegate = AWSSignatureV4Delegate(credentialsProvider: credentialsProvider!)
            MLNOfflineStorage.shared.delegate = self.signingDelegate
            mapSigningIntialised = true
        }
    }
    
    func initializeClient() {
        client = LocationTracker(provider: credentialsProvider!, trackerName: trackerName)
        clientIntialised = true
    }
    
    func setClientConfig(timeFilter: Bool, distanceFilter: Bool, accuracyFilter: Bool, timeInterval: Double? = nil, distanceInterval: Double? = nil) {
        var filters: [LocationFilter]? = []
        if timeFilter {
            filters!.append(TimeLocationFilter())
        }
        if distanceFilter {
            filters!.append(DistanceLocationFilter())
        }
        if accuracyFilter {
            filters!.append(AccuracyLocationFilter())
        }
        
        if filters!.isEmpty {
            filters = nil
        }
        
        let config = LocationTrackerConfig(locationFilters: filters, trackingDistanceInterval: distanceInterval, trackingTimeInterval: timeInterval)
        
        client.setTrackerConfig(config: config)
    }
    
    func showLocationDeniedRationale() {
        alertTitle = NSLocalizedString("locationManagerAlertTitle", comment: "")
        alertMessage = NSLocalizedString("locationManagerAlertText", comment: "")
        showAlert = true
    }

    func startTracking() {
        do {
            print("Tracking Started...")
            if(client == nil) {
                initializeClient()
            }
           //.startBackgroundTracking(mode: .Active)
            try client.startTracking()
            DispatchQueue.main.async { [self] in

                self.trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
                self.trackingButtonColor = .red
                self.trackingButtonIcon = "pause.circle"
                UserDefaultsHelper.save(value: true, key: .trackingActive)
            }
//            Task {
//                try await fetchGeofenceList()
//            }
//            subscribeToAWSNotifications()
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking: \(error)")
        }
    }
    
    func resumeTracking() {
        do {
            print("Tracking Resumed...")
            if(client == nil)
            {
                initializeClient()
            }
            try client.resumeTracking()//.resumeBackgroundTracking(mode: .Active)
            subscribeToAWSNotifications()
            DispatchQueue.main.async { [self] in
                self.trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
                self.trackingButtonColor = .red
                self.trackingButtonIcon = "pause.circle"
                UserDefaultsHelper.save(value: true, key: .trackingActive)
            }
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking: \(error)")
        }
    }
    
    func stopTracking() {
        print("Tracking Stopped...")
        client.stopTracking()//.stopBackgroundTracking()
        //unsubscribeFromAWSNotifications()
        trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
        trackingButtonColor = .blue
        trackingButtonIcon = "play.circle"
        UserDefaultsHelper.save(value: false, key: .trackingActive)
    }
    
    var mlnMapView: MLNMapView?
    var delegate: MapViewDelegate?
    var lastGetTrackingTime: Date?

    func getTrackingPoints(nextToken: String? = nil) async throws {
        guard UserDefaultsHelper.get(for: Bool.self, key: .trackingActive) ?? false else {
            return
        }
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
                self.delegate?.drawTrackingPoints( trackingPoints: trackingPoints)
            }
            if let nextToken = trackingData.nextToken {
                try await getTrackingPoints(nextToken: nextToken)
            }
        }
    }

    func batchEvaluateGeofences() async throws {
        guard lastGetTrackingTime != nil, currentLocation != nil, let geofenceCollectionArn = UserDefaultsHelper.get(for: String.self, key: .geofenceCollectionArn) else {
            return
        }
        guard let geofenceCollectionName = getGeofenceCollectionName(geofenceCollectionArn: geofenceCollectionArn) else { return }
        let deviceUpdate = LocationClientTypes.DevicePositionUpdate(deviceId: client.getDeviceId(), position: [currentLocation.coordinate.longitude, currentLocation.coordinate.latitude], sampleTime: lastGetTrackingTime)
        let input = BatchEvaluateGeofencesInput(collectionName: geofenceCollectionName, devicePositionUpdates: [deviceUpdate])
        _ = try await client.batchEvaluateGeofences(input: input)
    }
    
    func fetchGeofenceList() async throws {
        guard let geofenceCollectionName = getGeofenceCollectionName(geofenceCollectionArn: geofenceCollectionArn) else {
            return
        }
        let listGeofencesInput = ListGeofencesInput(collectionName: geofenceCollectionName, maxResults: 100, nextToken: nil)
        let geogenceLists = try await client.listGeofences(input: listGeofencesInput)
        DispatchQueue.main.async {
            self.delegate?.displayGeofences(geofences: geogenceLists!)
        }
    }
    
    func getGeofenceCollectionName(geofenceCollectionArn: String) -> String? {
        let components = geofenceCollectionArn.split(separator: ":")

        if let lastComponent = components.last {
            let nameComponents = lastComponent.split(separator: "/")
            if nameComponents.count > 1, let collectionNameSubstring = nameComponents.last {
                let collectionName = String(collectionNameSubstring)
                return collectionName
            } else {
                print("Collection name could not be extracted")
            }
        } else {
            print("Invalid ARN format")
        }
        return nil
    }
    
    func configureCognito() {
        showingCognitoConfiguration = true
    }
    
    func saveCognitoConfiguration() async throws {
        UserDefaultsHelper.save(value: identityPoolId, key: .identityPoolID)
        UserDefaultsHelper.save(value: mapName, key: .mapName)
        UserDefaultsHelper.save(value: trackerName, key: .trackerName)
        UserDefaultsHelper.save(value: geofenceCollectionArn, key: .geofenceCollectionArn)
        UserDefaultsHelper.save(value: websocketUrl, key: .websocketUrl)
        
        try await applyConfiguration()
    }
    
    func applyConfiguration() async throws {
        try await authWithCognito(identityPoolId: identityPoolId)
    }
    
    private func subscribeToAWSNotifications() {
        do {
            try createIoTManagerIfNeeded()
        }
        catch {
            print(error)
        }
//        {
//            guard let identityId = self.client.getDeviceId() else {
//                return
//            }
            
//            self.iotDataManager?.connectUsingWebSocket(withClientId: identityId, cleanSession: true) { status in
//                print("Websocket connection status \(status.rawValue)")
//                
//                switch status {
//                case .connected:
//                    let status = self.iotDataManager?.subscribe(
//                        toTopic: "\(identityId)/tracker",
//                        qoS: .messageDeliveryAttemptedAtMostOnce,
//                        messageCallback: { payload in
//                            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
//                            print("Message received: \(stringValue)")
//                            
//                            guard let model = try? JSONDecoder().decode(TrackingEventModel.self, from: payload) else { return }
//                            
//                            let eventText: String
//                            switch model.trackerEventType {
//                            case .enter:
//                                eventText = NSLocalizedString("GeofenceEnterEvent", comment: "")
//                            case .exit:
//                                eventText = NSLocalizedString("GeofenceExitEvent", comment: "")
//                            }
//                            DispatchQueue.main.async {
//                                let title = String(format: NSLocalizedString("GeofenceNotificationTitle", comment: ""), eventText)
//                                let description = String(format: NSLocalizedString("GeofenceNotificationDescription", comment: ""),  model.geofenceId, eventText, self.localizedDateString(from: model.eventTime))
//                                NotificationManager.scheduleNotification(title: title, body: description)
//                            }
//                        }
//                    )
//                    print("subscribe status \(String(describing: status))")
//                case .connectionError:
//                    print("subscribe status connectionError \(status)")
//                case .connectionRefused:
//                    print("subscribe status connectionRefused \(status)")
//                default:
//                    break
//                }
//            }
//            }
    }
    
    func localizedDateString(from jsonStringDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let date = isoFormatter.date(from: jsonStringDate) else {
            fatalError("Invalid date format")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: date)
    }

     func createIoTManagerIfNeeded() throws {
        let region = AmazonLocationRegion.toRegionString(identityPoolId: identityPoolId)

        iot = try AWSIoT.IoTClient(region: region)
        iotPublisher = iot.publisher
        let sink = iotPublisher!
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Publisher finished successfully.")
                case .failure(let error):
                    print("Publisher failed with error: \(error)")
                }
            },
            receiveValue: { value in
                print("Received IoTClient value: \(value)")
                // Handle the received value here
//                let stringValue = NSString(data: value, encoding: String.Encoding.utf8.rawValue)!
//                print("Message received: \(stringValue)")
//                
//                guard let model = try? JSONDecoder().decode(TrackingEventModel.self, from: payload) else { return }
//                
//                let eventText: String
//                switch model.trackerEventType {
//                case .enter:
//                    eventText = NSLocalizedString("GeofenceEnterEvent", comment: "")
//                case .exit:
//                    eventText = NSLocalizedString("GeofenceExitEvent", comment: "")
//                }
//                DispatchQueue.main.async {
//                    let title = String(format: NSLocalizedString("GeofenceNotificationTitle", comment: ""), eventText)
//                    let description = String(format: NSLocalizedString("GeofenceNotificationDescription", comment: ""),  model.geofenceId, eventText, self.localizedDateString(from: model.eventTime))
//                    NotificationManager.scheduleNotification(title: title, body: description)
//                }
            }
        )
    }
    
//    private func unsubscribeFromAWSNotifications() {
//        
//        guard let identityId = credentialsProvider?.getCognitoProvider() else {
//            return
//        }
//        
//        iotDataManager?.unsubscribeTopic("\(identityId)/tracker")
//        iotDataManager?.disconnect()
//    }
            
}
