import Foundation

struct CustomConnectionModel: Codable {
    var identityPoolId: String
    var userPoolClientId: String
    var userPoolId: String
    var userDomain: String
    var webSocketUrl: String
    
    var region: String {
        let regionDivider: Character = ":"
        return String(identityPoolId.prefix(while: { $0 != regionDivider }))
    }
}
