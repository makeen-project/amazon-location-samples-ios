# Sample App: AWS Location Service Integration

This sample app demonstrates how to integrate AWS Location Service with an iOS application using Amazon Cognito for authentication and tracking location updates in real-time. It showcases the usage of Amazon Location Service's Tracking and Authentication SDKs to authenticate users and track their location on a map.

Additional documentation for this sample application is available from the [Amazon Location Service documentation website](https://docs.aws.amazon.com/location/latest/developerguide/qs-ios-tracking.html).

- **Tracking SDK**: [Amazon Location Service Tracking SDK](https://github.com/aws-geospatial/amazon-location-mobile-tracking-sdk-ios)
- **Auth SDK**: [Amazon Location Service Authentication SDK](https://github.com/aws-geospatial/amazon-location-mobile-auth-sdk-ios)

## Installation

1. Clone this repository to your local machine.
2. Open `AWSLocationSampleApp.xcodeproj` project in Xcode.
3. Build and run the app on your iOS device or simulator.
4. Open `ConfigTemplate.xcconfig` file
5. Copy contents to a new file named `Config.xcconfig`
6. Configure AWS credentials in the app using one of the following methods:
  - Option 1. **Configure via Config.xcconfig**: Fill in the required values in the `Config.xcconfig` file to configure the AWS credentials. (Refer to the [Configuration](#configuration) section for details)
  - Option 2. **Configure via app**: Upon launching the app, navigate to the Config tab and enter your AWS Identity Pool ID, Map Name, Tracker Name and Geofence Collection ARN to configure the AWS credentials.

## Configuration

A template configuration file named `ConfigTemplate.xcconfig` is included in the root of the project. To use it:

1. Copy `ConfigTemplate.xcconfig` file to `Config.xcconfig`.
2. Fill in the following values in `Config.xcconfig`:
```
IDENTITY_POOL_ID = [Your Cognito Identity Pool ID] 
MAP_NAME = [Your Map Resource Name] 
TRACKER_NAME = [Your Tracker Resource Name] 
GEOFENCE_ARN = [Your Geofence Collection ARN] 
WEBSOCKET_URL = [Your IoT WebSocket URL] 
```

- **IDENTITY_POOL_ID**: Your AWS Cognito Identity Pool ID used for authenticating users.
- **MAP_NAME**: The name of the map resource in Amazon Location Service you want to use for displaying the map.
- **TRACKER_NAME**: The name of the tracker resource in Amazon Location Service used for tracking location updates.
- **GEOFENCE_ARN**: The Amazon Resource Name (ARN) of your geofence collection in Amazon Location Service. (Optional)
- **WEBSOCKET_URL**: The WebSocket URL used for geofence monitoring. (Optional)

These values are used to configure the app's connection to AWS services. If not provided in the `Config.xcconfig` file, they can be filled out manually in the app's Config tab.

## Filters

The app provides options to filter location tracking data based on time, distance, and accuracy:

- **Time Filter**: If enabled, location updates are sent only after the specified time interval has passed.
- **Distance Filter**: If enabled, location updates are sent only after moving a specified distance from the last reported location.
- **Accuracy Filter**: If enabled, location updates are filtered based on the specified accuracy level.

These filters help in optimizing the location tracking to suit different use cases and requirements.

## UI Automated Tests
In order to run the UI tests, you need to provide the AWS credentials in the `TestConfig.xcconfig` file.

1. Copy `TestConfigTemplate.xcconfig` file to `TestConfig.xcconfig`.
2. Fill in the following values in `TestConfig.xcconfig`:
```
TEST_IDENTITY_POOL_ID = [Your Cognito Identity Pool ID]
TEST_MAP_NAME = [Your Map Resource Name]
TEST_TRACKER_NAME = [Your Tracker Resource Name]
TEST_WEBSOCKET_URL = [Your IoT WebSocket URL]
TEST_GEOFENCE_ARN = [Your Geofence Collection ARN]
```
3. Run the UI tests by selecting the `AWSLocationSampleAppUITests` target and selecting Product -> Test from the Xcode menu.