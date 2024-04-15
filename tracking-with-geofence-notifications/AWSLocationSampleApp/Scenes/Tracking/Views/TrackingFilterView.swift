import SwiftUI

struct TrackingFilterView: View {
    @ObservedObject var authViewModel: AuthViewModel

    func setFilterValues() {
        authViewModel.setClientConfig(timeFilter: authViewModel.timeFilter, distanceFilter: authViewModel.distanceFilter, accuracyFilter: authViewModel.accuracyFilter, timeInterval: authViewModel.timeFilter ? authViewModel.timeInterval: nil, distanceInterval: authViewModel.distanceFilter ? authViewModel.distanceInterval: nil)
    }
    
    var body: some View {
        Toggle(isOn: $authViewModel.timeFilter, label: {
                Text(NSLocalizedString("TimeFilter", comment: ""))
            })
        .accessibilityIdentifier("TimeFilterToggle")
        .onChange(of: authViewModel.timeFilter, { oldValue, newValue in
            authViewModel.timeFilter = newValue
                setFilterValues()
            })
            
        if authViewModel.timeFilter {
            Stepper(String(format: NSLocalizedString("TimeFilterLabel", comment: ""), Int(authViewModel.timeInterval)), value: $authViewModel.timeInterval, in: 0...1000, step: 1)
                .accessibility(identifier: "TimeFilterStepper")
                .onChange(of: authViewModel.timeInterval, { oldValue, newValue in
                    authViewModel.timeInterval = newValue
                        setFilterValues()
                    })
            }
            
        Toggle(isOn: $authViewModel.distanceFilter, label: {
                Text(NSLocalizedString("DistanceFilter", comment: ""))
            })
        .accessibility(identifier: "DistanceFilterToggle")
        .onChange(of: authViewModel.distanceFilter, { oldValue, newValue in
            authViewModel.distanceFilter = newValue
                setFilterValues()
            })
            
        if authViewModel.distanceFilter {
            Stepper(String(format: NSLocalizedString("DistanceFilterLabel", comment: ""), Int(authViewModel.distanceInterval)), value: $authViewModel.distanceInterval, in: 0...10000, step: 1)
                .accessibility(identifier: "DistanceFilterStepper")
                .onChange(of: authViewModel.distanceInterval, { oldValue, newValue in
                    authViewModel.distanceInterval = newValue
                        setFilterValues()
                    })
            }
            
        Toggle(isOn: $authViewModel.accuracyFilter, label: {
                Text(NSLocalizedString("AccuracyFilter", comment: ""))
            })
        .accessibility(identifier: "AccuracyFilterToggle")
        .onChange(of: authViewModel.accuracyFilter, { oldValue, newValue in
            authViewModel.accuracyFilter = newValue
                setFilterValues()
            })
    }
}
