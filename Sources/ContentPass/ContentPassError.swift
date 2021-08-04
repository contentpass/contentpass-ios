public enum ContentPassError: Error {
    case unexpectedState(UnexpectedState)
    case missingOIDServiceConfiguration
    
    public enum UnexpectedState {
        case missingConfigurationAfterDiscovery
        case missingConfigurationDuringAuthorization
        case missingAuthorizationStateAfterAuthorization
    }
}
