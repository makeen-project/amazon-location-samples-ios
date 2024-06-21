import SwiftUI

struct ClientConfigView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Text("Identity Pool ID")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Identity Pool ID", text: $authViewModel.identityPoolId)
                    .accessibility(identifier: "IdentityPoolID")
                
                Text("Map Name")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Map Name", text: $authViewModel.mapName).accessibility(identifier: "MapName")
                
                Text("Tracker Name")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Tracker Name", text: $authViewModel.trackerName).accessibility(identifier: "TrackerName")
                
                Text("Websocket URL")
                    .fontWeight(.bold)
                TextField("Websocket URL", text: $authViewModel.websocketUrl).accessibility(identifier: "WebsocketURL")
                
                Text("Geofence Collection ARN")
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                TextField("Geofence Collection ARN", text: $authViewModel.geofenceCollectionArn).accessibility(identifier: "GeofenceCollectionARN")
                
                Button("Save Configuration") {
                    if authViewModel.identityPoolId.isEmpty || authViewModel.mapName.isEmpty || authViewModel.trackerName.isEmpty || authViewModel.websocketUrl.isEmpty || authViewModel.geofenceCollectionArn.isEmpty {
                        errorMessage = NSLocalizedString("FillAllFields", comment: "")
                        showError = true
                    }
                    else {
                        Task {
                            try await authViewModel.saveCognitoConfiguration()
                            isPresented = false
                        }
                    }
                }.accessibility(identifier: "SaveConfiguration")
                Text(errorMessage)
            }
            .navigationBarTitle(NSLocalizedString("SaveCognitoConfiguration", comment: ""), displayMode: .inline)
                       .navigationBarItems(trailing: Button(action: {
                           isPresented = false
                       }) {
                           Text(NSLocalizedString("Cancel", comment: "")).bold()
                       })
        }
    }
}
