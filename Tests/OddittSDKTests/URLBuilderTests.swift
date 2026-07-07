@testable import OddittSDK
import XCTest

final class URLBuilderTests: XCTestCase {
    // MARK: toQueryParameters

    func testOmitsNilFields() {
        let config = OddittWidgetConfig(country: "US")
        XCTAssertEqual(config.toQueryParameters(), ["country": "US"])
    }

    func testCoercesBooleans() {
        let config = OddittWidgetConfig(parlay: true, useCartoonImages: false)
        let params = config.toQueryParameters()
        XCTAssertEqual(params["parlay"], "true")
        XCTAssertEqual(params["useCartoonImages"], "false")
    }

    func testJoinsIntListsWithCommas() {
        let config = OddittWidgetConfig(sportIds: [1, 2, 3], leagueIds: [10])
        let params = config.toQueryParameters()
        XCTAssertEqual(params["sportIds"], "1,2,3")
        XCTAssertEqual(params["leagueIds"], "10")
    }

    func testDropsEmptyStringsAndLists() {
        let config = OddittWidgetConfig(country: "", sportIds: [])
        XCTAssertTrue(config.toQueryParameters().isEmpty)
    }

    func testCoercesExtraParams() {
        let config = OddittWidgetConfig(extraParams: [
            "minHitRateThreshold": 60,
            "operatorKeys": ["a", "b"],
            "includeDeeplinks": true,
        ])
        let params = config.toQueryParameters()
        XCTAssertEqual(params["minHitRateThreshold"], "60")
        XCTAssertEqual(params["operatorKeys"], "a,b")
        XCTAssertEqual(params["includeDeeplinks"], "true")
    }

    func testExtraParamsWinOverTypedFields() {
        let config = OddittWidgetConfig(country: "US", extraParams: ["country": "CA"])
        XCTAssertEqual(config.toQueryParameters()["country"], "CA")
    }

    func testNeverEmitsParentOrigin() {
        let config = OddittWidgetConfig(extraParams: ["parentOrigin": "https://evil.example"])
        XCTAssertNil(config.toQueryParameters()["parentOrigin"])
    }

    // MARK: buildWidgetUrl

    func testAppendsConfigAsQueryParams() throws {
        let url = buildWidgetUrl(
            baseUrl: "https://demo.odditt.com/",
            config: OddittWidgetConfig(country: "US", colorMode: "dark")
        )
        let components = try XCTUnwrap(URLComponents(string: url))
        XCTAssertEqual(components.host, "demo.odditt.com")
        XCTAssertTrue(url.contains("country=US"))
        XCTAssertTrue(url.contains("colorMode=dark"))
    }

    func testKeepsCommasLiteral() {
        let url = buildWidgetUrl(
            baseUrl: "https://demo.odditt.com/",
            config: OddittWidgetConfig(sportIds: [1, 2, 3])
        )
        XCTAssertTrue(url.contains("sportIds=1,2,3"))
    }

    func testPreservesExistingQueryParams() {
        let url = buildWidgetUrl(
            baseUrl: "https://demo.odditt.com/?debug=1",
            config: OddittWidgetConfig(country: "US")
        )
        XCTAssertTrue(url.contains("debug=1"))
        XCTAssertTrue(url.contains("country=US"))
    }

    func testConfigOverridesCollidingBaseParams() {
        let url = buildWidgetUrl(
            baseUrl: "https://demo.odditt.com/?country=CA",
            config: OddittWidgetConfig(country: "US")
        )
        XCTAssertTrue(url.contains("country=US"))
        XCTAssertFalse(url.contains("country=CA"))
    }

    func testHandlesHostPortLoopback() throws {
        let url = buildWidgetUrl(
            baseUrl: "http://10.0.2.2:3000",
            config: OddittWidgetConfig(country: "US")
        )
        let components = try XCTUnwrap(URLComponents(string: url))
        XCTAssertEqual(components.host, "10.0.2.2")
        XCTAssertEqual(components.port, 3000)
        XCTAssertTrue(url.contains("country=US"))
    }

    func testEmptyConfigProducesNoQuery() {
        let url = buildWidgetUrl(baseUrl: "https://demo.odditt.com/", config: OddittWidgetConfig())
        XCTAssertEqual(url, "https://demo.odditt.com/")
    }
}
