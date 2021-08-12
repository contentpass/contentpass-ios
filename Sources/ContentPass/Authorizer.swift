import UIKit
import AppAuth

class Authorizer: Authorizing {
    let clientId: String
    let clientSecret: String?
    let clientRedirectUri: URL
    let discoveryUrl: URL

    private var oidServiceConfiguration: OIDServiceConfiguration?

    private let scopes = ["openid", "offline_access", "contentpass"]

    private let client: OIDClientWrapping

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
            clientSecret: clientSecret,
            scopes: scopes,
            redirectURL: clientRedirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: ["cp_route": "login", "prompt": "consent"]
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
                let isValidSubscription = contentPassToken.body.auth && !contentPassToken.body.plans.isEmpty
                completionHandler(.success(isValidSubscription))
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

    private static func translateAuthorizationError(_ error: Error) -> Error {
        return error
    }
}

extension Authorizer {
    struct ContentPassTokenResponse: Codable {
        let contentpassToken: String
    }

    struct ContentPassToken {
        let header: Header
        let body: Body

        init?(tokenString: String) {
            let split = tokenString.split(separator: ".")
            guard
                split.count >= 2,
                let headerData = Data(urlSafeBase64Encoded: String(split[0])),
                let bodyData = Data(urlSafeBase64Encoded: String(split[1]))
            else { return nil }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                header = try decoder.decode(Header.self, from: headerData)
                body = try decoder.decode(Body.self, from: bodyData)
            } catch _ {
                return nil
            }

        }

        struct Header: Codable {
            let alg: String
        }
        struct Body: Codable {
            let auth: Bool
            let plans: [String]
            let aud: String
            let iat: Date
            let exp: Date
        }
    }
}

extension Data {
    init?(urlSafeBase64Encoded: String) {
        var stringtoDecode: String = urlSafeBase64Encoded.replacingOccurrences(of: "-", with: "+")
        stringtoDecode = stringtoDecode.replacingOccurrences(of: "_", with: "/")
        switch stringtoDecode.utf8.count % 4 {
            case 2:
                stringtoDecode += "=="
            case 3:
                stringtoDecode += "="
            default:
                break
        }
        guard let data = Data(base64Encoded: stringtoDecode, options: .ignoreUnknownCharacters) else {
            return nil
        }
        self = data
    }
}
