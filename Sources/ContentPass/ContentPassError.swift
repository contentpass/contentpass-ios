public enum ContentPassError: Error {
    case unexpectedState(UnexpectedState)
    case missingOIDServiceConfiguration
    case subscriptionDataCorrupted
    case corruptedResponseFromWeb
    case badHTTPStatusCode(Int)
    case oidAuthenticatedButMissingIdToken
    case userCanceledAuthentication

    public enum UnexpectedState {
        case missingSubscriptionData
        case missingConfigurationAfterDiscovery
        case missingConfigurationDuringAuthorization
        case missingAuthStateAfterAuthorization
    }
}
