import SwiftUI

struct TrackingBottomView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
           Button(action: {
               if(authViewModel.trackingButtonText == NSLocalizedString("StartTrackingLabel", comment: "")) {
                   authViewModel.startTracking()
               } else {
                   authViewModel.stopTracking()
               }
           }) {
               HStack {
                   Spacer()
                   Text("Tracking")
                       .foregroundColor(authViewModel.trackingButtonColor)
                       .background(.white)
                       .cornerRadius(15.0)
                   
                   Image(systemName: authViewModel.trackingButtonIcon)
                       .resizable()
                       .frame(width: 24, height: 24)
                       .padding(5)
                       .background(.white)
                       .foregroundColor(authViewModel.trackingButtonColor)

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
