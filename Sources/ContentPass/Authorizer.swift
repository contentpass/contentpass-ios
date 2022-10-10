import UIKit
import AppAuth

class Authorizer: Authorizing {
    let clientId: String
    let clientRedirectUri: URL
    let discoveryUrl: URL

    private var oidServiceConfiguration: OIDServiceConfiguration?

    private let scopes = ["openid", "offline_access", "contentpass"]

    private let client: OIDClientWrapping

    init(clientId: String, clientRedirectUri: URL, discoveryUrl: URL, client: OIDClientWrapping = OIDClientWrapper()) {
        defer {
            discoverConfiguration { [weak self] config, _ in
                self?.oidServiceConfiguration = config
            }
        }
        self.clientId = clientId
        self.clientRedirectUri = clientRedirectUri
        self.discoveryUrl = discoveryUrl
        self.client = client
    }

    private func discoverConfiguration(completionHandler: @escaping (OIDServiceConfiguration?, Error?) -> Void) {
        client.discoverConfiguration(forIssuer: discoveryUrl, completionHandler: completionHandler)
    }

    func authorize(presentingViewController: UIViewController, completionHandler: @escaping (Result<OIDAuthStateWrapping, Error>) -> Void) {
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
            clientSecret: nil,
            scopes: scopes,
            redirectURL: clientRedirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: ["cp_route": "login", "prompt": "consent", "cp_property": clientId]
        )
    }

    private func doAuthorization(presentingViewController: UIViewController, completionHandler: @escaping (Result<OIDAuthStateWrapping, Error>) -> Void) {
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
                        completionHandler(.failure(ContentPassError.unexpectedState(.missingAuthStateAfterAuthorization)))
                        return
                    }
                    completionHandler(.success(newAuthState))
                }
            )
        } catch let error {
            completionHandler(.failure(error))
        }
    }

    func validateSubscription(idToken: String, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        if let configuration = oidServiceConfiguration {
            doValidateSubscription(idToken: idToken, tokenUrl: configuration.tokenEndpoint, completionHandler: completionHandler)
        } else {
            discoverConfiguration { [weak self] configuration, error in
                if let error = error {
                    completionHandler(.failure(error))
                } else if let configuration = configuration {
                    self?.oidServiceConfiguration = configuration
                    self?.doValidateSubscription(idToken: idToken, tokenUrl: configuration.tokenEndpoint, completionHandler: completionHandler)
                } else {
                    completionHandler(.failure(ContentPassError.unexpectedState(.missingConfigurationAfterDiscovery)))
                }
            }
        }
    }

    private func doValidateSubscription(idToken: String, tokenUrl: URL, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let request = createValidateSubscriptionRequest(idToken: idToken, tokenUrl: tokenUrl)
        client.fireValidationRequest(request) { data, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard
                    let parsedResponse = try? decoder.decode(ContentPassTokenResponse.self, from: data),
                    let contentPassToken = ContentPassToken(tokenString: parsedResponse.contentpassToken)
                else {
                    completionHandler(.failure(ContentPassError.subscriptionDataCorrupted))
                    return
                }
                completionHandler(.success(contentPassToken.isSubscriptionValid))
            } else {
                completionHandler(.failure(ContentPassError.unexpectedState(.missingSubscriptionData)))
            }
        }
    }

    private func createValidateSubscriptionRequest(idToken: String, tokenUrl: URL) -> URLRequest {
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        let body = "grant_type=contentpass_token&subject_token=\(idToken)&client_id=\(clientId)"
        request.httpBody = body.data(using: .utf8)
        return request
    }

    static func translateAuthorizationError(_ error: Error) -> Error {
        let error = error as NSError
        if error.domain == "org.openid.appauth.general" && error.code == -3 {
            return ContentPassError.userCanceledAuthentication
        } else {
            return error
        }
    }
}
