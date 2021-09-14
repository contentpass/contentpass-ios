import XCTest
@testable import ContentPass

class ContentPassTokenTests: XCTestCase {

    static let validToken = "eyJhbGciOiJSUzI1NiJ9.eyJhdXRoIjp0cnVlLCJwbGFucyI6WyJjYTQ5MmFmNy0zMjBjLTQyYzktOWJhMC1iMmEzM2NmY2EzMDciXSwiYXVkIjoiNjliMjg5ODUiLCJpYXQiOjE2Mjg3NjYyOTIsImV4cCI6MTYyODk0MjY5Mn0"
    static let missingPlansToken = "ewogICJhbGciOiAiUlMyNTYiCn0.ewogICJhdXRoIjogdHJ1ZSwKICAicGxhbnMiOiBbXSwKICAiYXVkIjogIjY5YjI4OTg1IiwKICAiaWF0IjogMTYyODc2NjI5MiwKICAiZXhwIjogMTYyODk0MjY5Mgp9"
    static let noAuthToken = "ewogICJhbGciOiAiUlMyNTYiCn0.ewogICJhdXRoIjogZmFsc2UsCiAgInBsYW5zIjogWwogICAgImNhNDkyYWY3LTMyMGMtNDJjOS05YmEwLWIyYTMzY2ZjYTMwNyIKICBdLAogICJhdWQiOiAiNjliMjg5ODUiLAogICJpYXQiOiAxNjI4NzY2MjkyLAogICJleHAiOiAxNjI4OTQyNjkyCn0"

    func testContentPassTokenInitialization() {
        let decodedToken = ContentPassToken(tokenString: ContentPassTokenTests.validToken)

        XCTAssertNotNil(decodedToken)
        XCTAssertEqual(decodedToken?.header.alg, "RS256")
        XCTAssertEqual(decodedToken?.body.plans, ["ca492af7-320c-42c9-9ba0-b2a33cfca307"])
        XCTAssertEqual(decodedToken?.body.aud, "69b28985")
        XCTAssertEqual(decodedToken?.body.auth, true)
        XCTAssertEqual(decodedToken?.body.iat, Date(timeIntervalSince1970: 1628766292))
        XCTAssertEqual(decodedToken?.body.exp, Date(timeIntervalSince1970: 1628942692))
    }

    func testContentPassTokenIsSubscriptionValid() {
        let validToken = ContentPassToken(tokenString: ContentPassTokenTests.validToken)
        XCTAssert(validToken?.isSubscriptionValid ?? false)

        let missingPlansToken = ContentPassToken(tokenString: ContentPassTokenTests.missingPlansToken)
        XCTAssertFalse(missingPlansToken?.isSubscriptionValid ?? true)

        let noAuthToken = ContentPassToken(tokenString: ContentPassTokenTests.noAuthToken)
        XCTAssertFalse(noAuthToken?.isSubscriptionValid ?? true)
    }
}
