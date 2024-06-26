import SwiftUI
import AmazonLocationiOSTrackingSDK

struct TabsContentView: View {
    @State private var selectedTab = "Config"
    @ObservedObject var authViewModel = AuthViewModel(identityPoolId: Config.identityPoolId, mapName: Config.mapName, trackerName: Config.trackerName, geofenceCollectionArn: Config.geofenceARN, websocketUrl: Config.websocketUrl)
    var body: some View {
        TabView(selection: $selectedTab) {
            AWSConnectionView(authViewModel: authViewModel)
                .tabItem {
                    Label("Config", systemImage: "gear")
                }
                .tag("Config")
            TrackingView(authViewModel: authViewModel)
                .tabItem {
                    Label("Tracking", systemImage: "location.fill")
                }
                .tag("Tracking")
        }
        .onAppear() {
            if !authViewModel.identityPoolId.isEmpty {
                Task {
                    do {
                        try await authViewModel.authWithCognito(identityPoolId: authViewModel.identityPoolId)
                    }
                    catch {
                        authViewModel.showErrorAlertPopup(title: "Error", message: "Error in authentication with cognito: \(error.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        if UserDefaultsHelper.get(for: Bool.self, key: .trackingActive) ?? false {
                            selectedTab = "Tracking"
                            authViewModel.resumeTracking()
                        }
                        else {
                            selectedTab = "Config"
                        }
                    }
                }
            }
        }
    }
}
