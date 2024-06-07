import Foundation
import SwiftUI
import AmazonLocationiOSAuthSDK
import AmazonLocationiOSTrackingSDK
import CoreLocation
import MapLibre

final class AuthViewModel : ObservableObject {
    @Published var trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
    @Published var trackingButtonColor = Color.blue
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
    
    var loginDelegate: LoginViewModelOutputDelegate?
    var client:LocationTracker!
    var signingDelegate: MLNOfflineStorageDelegate?
    var currentLocation: CLLocation!
    
    private var iotDataManager: AWSIoTDataManager?
    private var iotManager: AWSIoTManager?
    private var iot: AWSIoT?
    
    var authHelper: AuthHelper
    var credentialsProvider: LocationCredentialsProvider?
    
    func populateFilterValues() {
        guard let config = client?.getTrackerConfig() else {
            return
        }
        let filters = config.locationFilters
        timeFilter = filters.contains { $0 is TimeLocationFilter }
        distanceFilter = filters.contains { $0 is DistanceLocationFilter }
        accuracyFilter = filters.contains { $0 is AccuracyLocationFilter }
        
        timeInterval = config.trackingTimeInterval
        distanceInterval = config.trackingDistanceInterval
    }
    
    init(identityPoolId: String, mapName: String, trackerName: String, geofenceCollectionArn: String, websocketUrl: String) {
        self.identityPoolId = identityPoolId
        self.mapName = mapName
        self.trackerName = trackerName
        self.geofenceCollectionArn = geofenceCollectionArn
        self.websocketUrl = websocketUrl
        self.authHelper = AuthHelper()
    }
    
    func authWithCognito(identityPoolId: String?) {
        
        guard let identityPoolId = identityPoolId?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            
            let model = AlertModel(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("NotAllFieldsAreConfigured", comment: ""), okButton: NSLocalizedString("Ok", comment: ""))
            loginDelegate?.showAlert(model)
            
            return
        }
        credentialsProvider = authHelper.authenticateWithCognitoUserPool(identityPoolId: identityPoolId)
        initializeClient()
        
        mapViewSigning()
        
        populateFilterValues()
    }
    
    func mapViewSigning() {
        let region = AWSEndpoint.toRegionType(identityPoolId: identityPoolId)
        // register a delegate that will handle SigV4 signing
        signingDelegate = AWSSignatureV4Delegate(region: region!, identityPoolId: identityPoolId)
        MLNOfflineStorage.shared.delegate = signingDelegate
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
            if(client == nil)
            {
                authWithCognito(identityPoolId: identityPoolId)
            }
            fetchGeofenceList()
            try client.startBackgroundTracking(mode: .Active)
            subscribeToAWSNotifications()
            trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
            trackingButtonColor = .red
            UserDefaultsHelper.save(value: true, key: .trackingActive)
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking")
        }
    }
    
    func resumeTracking() {
        do {
            print("Tracking Resumed...")
            if(client == nil)
            {
                authWithCognito(identityPoolId: identityPoolId)
            }
            try client.resumeBackgroundTracking(mode: .Active)
            subscribeToAWSNotifications()
            trackingButtonText = NSLocalizedString("StopTrackingLabel", comment: "")
            trackingButtonColor = .red
            UserDefaultsHelper.save(value: true, key: .trackingActive)
        } catch TrackingLocationError.permissionDenied {
            showLocationDeniedRationale()
        } catch {
            print("error in tracking")
        }
    }
    
    func stopTracking() {
        print("Tracking Stopped...")
        client.stopBackgroundTracking()
        unsubscribeFromAWSNotifications()
        trackingButtonText = NSLocalizedString("StartTrackingLabel", comment: "")
        trackingButtonColor = .blue
        UserDefaultsHelper.save(value: false, key: .trackingActive)
    }
    
    var mlnMapView: MLNMapView?
    var delegate: MapViewDelegate?
    var lastGetTrackingTime: Date?

    func getTrackingPoints(nextToken: String? = nil) {
        guard UserDefaultsHelper.get(for: Bool.self, key: .trackingActive) ?? false else {
            return
        }
        let startTime: Date = Date().addingTimeInterval(-86400)
        var endTime: Date = Date()
        if lastGetTrackingTime != nil {
            endTime = lastGetTrackingTime!
        }
        client?.getTrackerDeviceLocation(nextToken: nextToken, startTime: startTime, endTime: endTime, completion: { [weak self] result in
            switch result {
            case .success(let response):
                self?.lastGetTrackingTime = Date()
                let positions = response.devicePositions!.sorted { (position1, position2) -> Bool in
                    let timestamp1 = position1.sampleTime ?? Date()
                    let timestamp2 = position2.sampleTime ?? Date()
                    
                    return timestamp1 > timestamp2
                }
                let trackingPoints = positions.compactMap { position -> CLLocationCoordinate2D? in
                    guard let latitude = position.position?.latitude, let longitude = position.position?.longitude else {
                        return nil
                    }
                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
                DispatchQueue.main.async {
                    self?.delegate?.drawTrackingPoints( trackingPoints: trackingPoints)
                }
                // If nextToken is not nil, recursively call to get more data
                if let nextToken = response.nextToken {
                    self?.getTrackingPoints(nextToken: nextToken)
                }
            case .failure(let error):
                print(error)
            }
        })
    }

    func batchEvaluateGeofences() {
        guard lastGetTrackingTime != nil, currentLocation != nil, let geofenceCollectionArn = UserDefaultsHelper.get(for: String.self, key: .geofenceCollectionArn) else {
            return
        }
        guard let geofenceCollectionName = getGeofenceCollectionName(geofenceCollectionArn: geofenceCollectionArn) else { return }
        let deviceUpdate = AWSLocationDevicePositionUpdate()
        deviceUpdate?.deviceId = client.getDeviceId()
        deviceUpdate?.position = [NSNumber(value: currentLocation.coordinate.longitude), NSNumber( value: currentLocation.coordinate.latitude)]
        deviceUpdate?.sampleTime =  lastGetTrackingTime
        let deviceUpdates: [AWSLocationDevicePositionUpdate] = Array(arrayLiteral: deviceUpdate!) //[deviceUpdate!]
        let request = AWSLocationBatchEvaluateGeofencesRequest()!
        request.collectionName = geofenceCollectionName
        request.devicePositionUpdates = deviceUpdates
        let result = AWSLocation.default().batchEvaluateGeofences(request)
        
        result.continueWith { response in
            if response.result != nil {
               print("batchEvaluateGeofences success")
               
            } else {
                let defaultError = NSError(domain: "Tracking", code: -1)
                let error = response.error ?? defaultError
                print("batchEvaluateGeofences error \(error)")
            }
            
            return nil
        }
    }
    
    func fetchGeofenceList() {
        guard let geofenceCollectionArn = UserDefaultsHelper.get(for: String.self, key: .geofenceCollectionArn) else {
            return
        }
        guard let geofenceCollectionName = getGeofenceCollectionName(geofenceCollectionArn: geofenceCollectionArn) else { return }
        
        let request = AWSLocationListGeofencesRequest()!
        request.collectionName = geofenceCollectionName
    
        let result = AWSLocation.default().listGeofences(request)
        
        result.continueWith {[weak self] response in
            if let error = response.error {
                print("error \(error)")

            } else if let taskResult = response.result {
                print("taskResult \(taskResult)")
                DispatchQueue.main.async {
                    self?.delegate?.displayGeofences(geofences: taskResult.entries!)
                }
            }
            
            return nil
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
    
    func saveCognitoConfiguration() {
        UserDefaultsHelper.save(value: identityPoolId, key: .identityPoolID)
        UserDefaultsHelper.save(value: mapName, key: .mapName)
        UserDefaultsHelper.save(value: trackerName, key: .trackerName)
        UserDefaultsHelper.save(value: geofenceCollectionArn, key: .geofenceCollectionArn)
        UserDefaultsHelper.save(value: websocketUrl, key: .websocketUrl)
        
        applyConfiguration()
    }
    
    func applyConfiguration() {
        authWithCognito(identityPoolId: identityPoolId)
    }
    
    private func subscribeToAWSNotifications() {
        createIoTManagerIfNeeded {
            guard let identityId = self.client.getDeviceId() else {
                return
            }
            
            self.iotDataManager?.connectUsingWebSocket(withClientId: identityId, cleanSession: true) { status in
                print("Websocket connection status \(status.rawValue)")
                
                switch status {
                case .connected:
                    let status = self.iotDataManager?.subscribe(
                        toTopic: "\(identityId)/tracker",
                        qoS: .messageDeliveryAttemptedAtMostOnce,
                        messageCallback: { payload in
                            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)!
                            print("Message received: \(stringValue)")
                            
                            guard let model = try? JSONDecoder().decode(TrackingEventModel.self, from: payload) else { return }
                            
                            let eventText: String
                            switch model.trackerEventType {
                            case .enter:
                                eventText = NSLocalizedString("GeofenceEnterEvent", comment: "")
                            case .exit:
                                eventText = NSLocalizedString("GeofenceExitEvent", comment: "")
                            }
                            DispatchQueue.main.async {
                                let title = String(format: NSLocalizedString("GeofenceNotificationTitle", comment: ""), eventText)
                                let description = String(format: NSLocalizedString("GeofenceNotificationDescription", comment: ""),  model.geofenceId, eventText, self.localizedDateString(from: model.eventTime))
                                NotificationManager.scheduleNotification(title: title, body: description)
                            }
                        }
                    )
                    print("subscribe status \(String(describing: status))")
                case .connectionError:
                    print("subscribe status connectionError \(status)")
                case .connectionRefused:
                    print("subscribe status connectionRefused \(status)")
                default:
                    break
                }
            }
            }
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
    
    private func createIoTManagerIfNeeded(completion: @escaping ()->()) {
        guard iotDataManager == nil else {
            completion()
            return
        }
        iotManager = AWSIoTManager.default()
        iot = AWSIoT(forKey: "default")
        
        let iotEndPoint = AWSEndpoint(
            urlString: "wss://\(self.websocketUrl)/mqtt")
        var region = AWSEndpoint.toRegionType(identityPoolId: identityPoolId)
        if let regionFromURL = iotEndPoint?.regionType, regionFromURL != .Unknown {
            region = regionFromURL
        }
                
        let iotDataConfiguration = AWSServiceConfiguration(
            region: region!,
            endpoint: iotEndPoint,
            credentialsProvider: credentialsProvider?.getCognitoProvider()
        )
        
        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: "MyAWSIoTDataManager")
        iotDataManager = AWSIoTDataManager(forKey: "MyAWSIoTDataManager")
        
        completion()
    }
    
    private func unsubscribeFromAWSNotifications() {
        guard let identityId = AWSMobileClient.default().identityId else {
            return
        }
        
        iotDataManager?.unsubscribeTopic("\(identityId)/tracker")
        iotDataManager?.disconnect()
    }
}
