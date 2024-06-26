import AmazonLocationiOSAuthSDK
import AWSIoT
import AWSIoTEvents

extension AmazonLocationClient {

    public func initialiseIOTClient(region: String) async throws -> IoTClient? {
        if let resolver = try locationProvider.getCognitoProvider()?.getStaticCredentialsResolver() {
            let clientConfig = try await IoTClient.IoTClientConfiguration(awsCredentialIdentityResolver: resolver, region: locationProvider.getRegion(), signingRegion: locationProvider.getRegion())
            let iot = try AWSIoT.IoTClient(region: region)
            return iot
        }
        return nil
    }
}
