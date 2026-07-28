import Foundation

/// Typed representations of the messages the widget posts back to its host.
///
/// The widget sends every signal as an envelope `{ type, payload, timestamp }`.
/// Each case corresponds to one wire `type`. ``contentHeightChanged`` is
/// synthesized by this SDK (not the widget) from an injected `ResizeObserver`.
public enum OddittSignal {
    /// `WIDGET_READY` — the widget mounted and is interactive.
    case widgetReady(timestamp: Int?)
    /// `WIDGET_EMPTY` — no flows for the current params; host should collapse.
    case widgetEmpty(timestamp: Int?)
    /// `WIDGET_ERROR` — a flows fetch failed.
    case widgetError(message: String, status: Int?, phase: String, timestamp: Int?)
    /// `BET_CLICKED` — the user tapped a bet CTA.
    case betClicked(
        flowId: String,
        flowType: String,
        buttonPayload: String?,
        data: [String: Any],
        rawJson: String,
        timestamp: Int?
    )
    /// `PAGE_LOADED` — a new page of flows was appended.
    case pageLoaded(page: Int, itemCount: Int, newItemCount: Int, timestamp: Int?)
    /// `FILTER_CHANGED` — the user changed a carousel filter.
    case filterChanged(payload: [String: Any], timestamp: Int?)
    /// `GRAPH_EXPANDED` — the user expanded a card/graph.
    case graphExpanded(flowId: String, flowType: String, timestamp: Int?)
    /// `GRAPH_COLLAPSED` — the user collapsed a card/graph.
    case graphCollapsed(flowId: String, flowType: String, timestamp: Int?)
    /// SDK-synthesized content height, in CSS pixels. Drives auto-sizing.
    case contentHeightChanged(height: Double, timestamp: Int?)
    /// SDK-synthesized: the widget asked to open a URL outside the embed — the
    /// affiliate click-out (`window.open(url, "_blank")`) or a `target="_blank"`
    /// anchor. Opened in Safari unless the host sets `onExternalUrl`.
    case externalUrl(url: String, target: String, timestamp: Int?)
    /// Any envelope whose wire `type` this SDK version does not recognize.
    case unknown(type: String, raw: [String: Any], timestamp: Int?)

    /// Milliseconds since epoch, as reported by the widget envelope (if present).
    public var timestamp: Int? {
        switch self {
        case let .widgetReady(timestamp),
             let .widgetEmpty(timestamp),
             let .contentHeightChanged(_, timestamp):
            timestamp
        case let .widgetError(_, _, _, timestamp),
             let .pageLoaded(_, _, _, timestamp):
            timestamp
        case let .betClicked(_, _, _, _, _, timestamp):
            timestamp
        case let .filterChanged(_, timestamp),
             let .unknown(_, _, timestamp):
            timestamp
        case let .graphExpanded(_, _, timestamp),
             let .graphCollapsed(_, _, timestamp),
             let .externalUrl(_, _, timestamp):
            timestamp
        }
    }
}

public extension OddittSignal {
    /// Convenience accessor for a `betClicked`'s American odds, if present.
    var betOddsAmerican: Int? {
        guard case let .betClicked(_, _, _, data, _, _) = self else { return nil }
        let value = data["oddsAmerican"] ?? data["odds"]
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    /// Convenience accessor for a `betClicked`'s human-readable description.
    var betDescription: String? {
        guard case let .betClicked(_, _, _, data, _, _) = self else { return nil }
        return data["betDescription"] as? String
    }
}
