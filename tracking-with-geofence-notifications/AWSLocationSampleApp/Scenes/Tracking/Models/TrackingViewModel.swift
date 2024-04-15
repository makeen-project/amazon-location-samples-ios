enum TrackerEventType: String, Codable {
    case enter = "ENTER"
    case exit = "EXIT"
}

struct TrackingEventModel: Codable {
    let trackerEventType: TrackerEventType
    let source: String
    let eventTime: String
    let geofenceId: String
}
