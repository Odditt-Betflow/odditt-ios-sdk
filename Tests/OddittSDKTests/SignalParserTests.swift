import XCTest
@testable import OddittSDK

final class SignalParserTests: XCTestCase {
    private func envelope(_ type: String, _ payload: [String: Any]) -> String {
        let object: [String: Any] = ["type": type, "payload": payload, "timestamp": 1_700_000_000_000]
        let data = try! JSONSerialization.data(withJSONObject: object)
        return String(data: data, encoding: .utf8)!
    }

    func testParsesWidgetReady() {
        guard case let .widgetReady(timestamp)? = parseSignal(envelope("WIDGET_READY", [:])) else {
            return XCTFail("expected widgetReady")
        }
        XCTAssertEqual(timestamp, 1_700_000_000_000)
    }

    func testParsesWidgetEmpty() {
        guard case .widgetEmpty? = parseSignal(envelope("WIDGET_EMPTY", [:])) else {
            return XCTFail("expected widgetEmpty")
        }
    }

    func testParsesWidgetErrorWithFields() {
        guard case let .widgetError(message, status, phase, _)? =
            parseSignal(envelope("WIDGET_ERROR", ["message": "boom", "status": 500, "phase": "retry"]))
        else {
            return XCTFail("expected widgetError")
        }
        XCTAssertEqual(message, "boom")
        XCTAssertEqual(status, 500)
        XCTAssertEqual(phase, "retry")
    }

    func testWidgetErrorToleratesNullStatusAndMissingMessage() {
        guard case let .widgetError(message, status, _, _)? =
            parseSignal(envelope("WIDGET_ERROR", ["status": NSNull(), "phase": "initial"]))
        else {
            return XCTFail("expected widgetError")
        }
        XCTAssertNil(status)
        XCTAssertEqual(message, "Unknown error")
    }

    func testParsesBetClickedWithAccessors() {
        let signal = parseSignal(envelope("BET_CLICKED", [
            "flowId": "f1",
            "flowType": "funflow",
            "buttonPayload": "deep://link",
            "data": [
                "eventBettingMarketPositionId": 42,
                "playerName": "Patrick Mahomes",
                "betDescription": "Pass Yards Over 250.5",
                "oddsAmerican": 125,
                "displayLineValue": "250.5",
            ],
        ]))
        guard case let .betClicked(flowId, flowType, buttonPayload, data, rawJson, _)? = signal else {
            return XCTFail("expected betClicked")
        }
        XCTAssertEqual(flowId, "f1")
        XCTAssertEqual(flowType, "funflow")
        XCTAssertEqual(buttonPayload, "deep://link")
        XCTAssertEqual(data["eventBettingMarketPositionId"] as? Int, 42)
        XCTAssertTrue(rawJson.contains("BET_CLICKED"))
        XCTAssertEqual(signal?.betOddsAmerican, 125)
        XCTAssertEqual(signal?.betDescription, "Pass Yards Over 250.5")
    }

    func testParsesPageLoaded() {
        guard case let .pageLoaded(page, itemCount, newItemCount, _)? =
            parseSignal(envelope("PAGE_LOADED", ["page": 2, "itemCount": 24, "newItemCount": 12]))
        else {
            return XCTFail("expected pageLoaded")
        }
        XCTAssertEqual(page, 2)
        XCTAssertEqual(itemCount, 24)
        XCTAssertEqual(newItemCount, 12)
    }

    func testParsesFilterChangedPreservingPayload() {
        guard case let .filterChanged(payload, _)? =
            parseSignal(envelope("FILTER_CHANGED", ["productMode": "sportsbook", "widgetMode": "operator"]))
        else {
            return XCTFail("expected filterChanged")
        }
        XCTAssertEqual(payload["productMode"] as? String, "sportsbook")
    }

    func testParsesGraphExpandedAndCollapsed() {
        guard case .graphExpanded? = parseSignal(envelope("GRAPH_EXPANDED", ["flowId": "a", "flowType": "b"])) else {
            return XCTFail("expected graphExpanded")
        }
        guard case .graphCollapsed? = parseSignal(envelope("GRAPH_COLLAPSED", ["flowId": "a", "flowType": "b"])) else {
            return XCTFail("expected graphCollapsed")
        }
    }

    func testParsesContentHeight() {
        guard case let .contentHeightChanged(height, _)? =
            parseSignal(envelope("__CONTENT_HEIGHT__", ["height": 640.5]))
        else {
            return XCTFail("expected contentHeightChanged")
        }
        XCTAssertEqual(height, 640.5)
    }

    func testContentHeightWithUnparseableHeightReturnsNil() {
        XCTAssertNil(parseSignal(envelope("__CONTENT_HEIGHT__", ["height": "nope"])))
    }

    func testUnknownTypeYieldsUnknownSignal() {
        guard case let .unknown(type, raw, _)? = parseSignal(envelope("SOMETHING_NEW", ["x": 1])) else {
            return XCTFail("expected unknown")
        }
        XCTAssertEqual(type, "SOMETHING_NEW")
        XCTAssertEqual(raw["type"] as? String, "SOMETHING_NEW")
    }

    func testReturnsNilForNonJsonAndObjectsWithoutStringType() {
        XCTAssertNil(parseSignal("not json"))
        XCTAssertNil(parseSignal("{\"payload\":{}}"))
        XCTAssertNil(parseSignal("[1,2,3]"))
    }
}
