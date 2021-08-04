import UIKit
import AppAuth

class Authorizer: Authorizing {
    private let clientId: String
    private let clientSecret: String?
    private let clientRedirectUri: URL
    private let discoveryUrl: URL
    
    private var oidServiceConfiguration: OIDServiceConfiguration?
    
    private let scopes = ["openid", "offline_access", "contentpass"]
    
    private var client: OIDClientWrapping
    
    init(clientId: String, clientSecret: String?, clientRedirectUri: URL, discoveryUrl: URL, client: OIDClientWrapping = OIDClientWrapper()) {
        defer {
            discoverConfiguration { [weak self] config, _ in
                self?.oidServiceConfiguration = config
            }
        }
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.clientRedirectUri = clientRedirectUri
        self.discoveryUrl = discoveryUrl
        self.client = client
    }
    
    private func discoverConfiguration(completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void) {
        client.discoverConfiguration(forIssuer: discoveryUrl, completionHandler: completionHandler)
    }
    
    func authorize(presentingViewController: UIViewController, completionHandler: @escaping (Result<OIDAuthState, Error>) -> Void) {
        if oidServiceConfiguration != nil {
            doAuthorization(presentingViewController: presentingViewController, completionHandler: completionHandler)
        } else {
            discoverConfiguration { [weak self] configuration, error in
                if let error = error {
                    completionHandler(.failure(error))
                } else if let configuration = configuration {
                    self?.oidServiceConfiguration = configuration
                    self?.doAuthorization(presentingViewController: presentingViewController, completionHandler: completionHandler)
                } else {
                    completionHandler(.failure(ContentPassError.unexpectedState(.missingConfigurationAfterDiscovery)))
                }
            }
        }
    }
    
    private func createAuthorizationRequest() throws -> OIDAuthorizationRequest {
        guard let configuration = oidServiceConfiguration else {
            throw ContentPassError.unexpectedState(.missingConfigurationDuringAuthorization)
        }
        
        return OIDAuthorizationRequest(
            configuration: configuration,
            clientId: clientId,
            clientSecret: clientSecret,
            scopes: scopes,
            redirectURL: clientRedirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: ["prompt": "consent"]
        )
    }
    
    private func doAuthorization(presentingViewController: UIViewController, completionHandler: @escaping (Result<OIDAuthState, Error>) -> Void) {
        do {
            let request = try createAuthorizationRequest()
            client.doAuthorization(
                byPresenting: request,
                presenting: presentingViewController,
                completionHandler: { newAuthState, error in
                    if let error = error {
                        let result = Authorizer.translateAuthorizationError(error)
                        completionHandler(.failure(result))
                        return
                    }
                    guard let newAuthState = newAuthState else {
                        completionHandler(.failure(ContentPassError.unexpectedState(.missingAuthorizationStateAfterAuthorization)))
                        return
                    }
                    completionHandler(.success(newAuthState))
                }
            )
        } catch let error {
            completionHandler(.failure(error))
        }
    }
    
    private static func translateAuthorizationError(_ error: Error) -> Error {
        return error
    }
}
