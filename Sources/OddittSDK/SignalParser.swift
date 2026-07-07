import Foundation

/// Decode a raw bridge message (JSON string) into a typed ``OddittSignal``.
///
/// Handles both the widget's `{ type, payload, timestamp }` envelope and the
/// SDK-synthesized height message (`__CONTENT_HEIGHT__`). Returns `nil` for
/// input that is not a JSON object with a string `type` — callers should treat
/// `nil` as "ignore this message".
///
/// Validation is lenient: missing/mistyped payload fields fall back to safe
/// defaults rather than throwing. Unrecognized `type` values yield
/// ``OddittSignal/unknown(type:raw:timestamp:)`` rather than `nil`, to stay
/// forward-compatible.
public func parseSignal(_ raw: String) -> OddittSignal? {
    guard let data = raw.data(using: .utf8) else { return nil }
    guard let json = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
          let map = json as? [String: Any],
          let type = map["type"] as? String
    else {
        return nil
    }

    let payload = asMap(map["payload"])
    let timestamp = asInt(map["timestamp"])

    switch type {
    case "__CONTENT_HEIGHT__":
        guard let height = asDouble(payload["height"]) else { return nil }
        return .contentHeightChanged(height: height, timestamp: timestamp)

    case "WIDGET_READY":
        return .widgetReady(timestamp: timestamp)

    case "WIDGET_EMPTY":
        return .widgetEmpty(timestamp: timestamp)

    case "WIDGET_ERROR":
        return .widgetError(
            message: asString(payload["message"]) ?? "Unknown error",
            status: asInt(payload["status"]),
            phase: asString(payload["phase"]) ?? "initial",
            timestamp: timestamp
        )

    case "BET_CLICKED":
        return .betClicked(
            flowId: asString(payload["flowId"]) ?? "",
            flowType: asString(payload["flowType"]) ?? "",
            buttonPayload: asString(payload["buttonPayload"]),
            data: asMap(payload["data"]),
            rawJson: raw,
            timestamp: timestamp
        )

    case "PAGE_LOADED":
        return .pageLoaded(
            page: asInt(payload["page"]) ?? 0,
            itemCount: asInt(payload["itemCount"]) ?? 0,
            newItemCount: asInt(payload["newItemCount"]) ?? 0,
            timestamp: timestamp
        )

    case "FILTER_CHANGED":
        return .filterChanged(payload: payload, timestamp: timestamp)

    case "GRAPH_EXPANDED":
        return .graphExpanded(
            flowId: asString(payload["flowId"]) ?? "",
            flowType: asString(payload["flowType"]) ?? "",
            timestamp: timestamp
        )

    case "GRAPH_COLLAPSED":
        return .graphCollapsed(
            flowId: asString(payload["flowId"]) ?? "",
            flowType: asString(payload["flowType"]) ?? "",
            timestamp: timestamp
        )

    default:
        return .unknown(type: type, raw: map, timestamp: timestamp)
    }
}

private func asMap(_ value: Any?) -> [String: Any] {
    value as? [String: Any] ?? [:]
}

private func asString(_ value: Any?) -> String? {
    value as? String
}

private func asInt(_ value: Any?) -> Int? {
    if let number = value as? NSNumber { return number.intValue }
    if let string = value as? String { return Int(string) }
    return nil
}

private func asDouble(_ value: Any?) -> Double? {
    if let number = value as? NSNumber { return number.doubleValue }
    if let string = value as? String { return Double(string) }
    return nil
}
