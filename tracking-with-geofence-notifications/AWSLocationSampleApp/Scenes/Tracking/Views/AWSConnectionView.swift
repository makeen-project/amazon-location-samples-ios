import SwiftUI
import AmazonLocationiOSTrackingSDK

struct AWSConnectionView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
        VStack {
            Button(action: {
                authViewModel.configureCognito()
            }) {
                Text(NSLocalizedString("CognitoConfigurationText", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15.0)
            }
            .accessibility(identifier: "CognitoConfiguration")
            .sheet(isPresented: $authViewModel.showingCognitoConfiguration) {
                ClientConfigView(isPresented: $authViewModel.showingCognitoConfiguration, authViewModel: authViewModel)
            }
            .alert(isPresented: $authViewModel.showAlert) {
                Alert(
                    title: Text(authViewModel.alertTitle),
                    message: Text(authViewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            if authViewModel.clientIntialised {
                TrackingFilterView(authViewModel: authViewModel)
                    .padding(20)
            }

        }
    }
}
