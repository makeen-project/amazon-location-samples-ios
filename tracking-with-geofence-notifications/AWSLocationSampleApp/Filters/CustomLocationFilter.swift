import Foundation
import AmazonLocationiOSTrackingSDK

class CustomLocationFilter : LocationFilter {
    func shouldUpload(
        currentLocation: LocationEntity,
        previousLocation: LocationEntity?,
        trackerConfig: LocationTrackerConfig
    ) -> Bool {
        // Example custom filter to only upload on Fridays
        let time = currentLocation.timestamp
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: time!)
        return dayOfWeek == 6
    }
}
