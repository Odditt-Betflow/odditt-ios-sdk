import Foundation

/// Compose the full widget URL from a `baseUrl` and `config`.
///
/// The widget is served at the root path with its config passed as query
/// parameters, e.g. `https://demo.odditt.com/?country=US&sportIds=1,2`.
///
/// Any query params already present on `baseUrl` are preserved; `config` values
/// override them on key collision. `parentOrigin` is never emitted. Commas in
/// list params are kept literal so the widget's parser can split them.
///
/// A `device_type` param is seeded from `deviceType` (default `"ios"`) so the
/// widget's affiliate click-out picks the right deep link. Without it the widget
/// falls back to user-agent sniffing, which is unreliable inside a `WKWebView`
/// and silently degrades to the desktop link. `config` — and therefore
/// `extraParams["device_type"]` — still overrides the seeded value.
public func buildWidgetUrl(
    baseUrl: String,
    config: OddittWidgetConfig,
    deviceType: String = "ios"
) -> String {
    var withoutFragment = baseUrl
    var fragment = ""
    if let hashIdx = baseUrl.firstIndex(of: "#") {
        withoutFragment = String(baseUrl[..<hashIdx])
        fragment = String(baseUrl[hashIdx...])
    }

    var path = withoutFragment
    var existingQuery = ""
    if let qIdx = withoutFragment.firstIndex(of: "?") {
        path = String(withoutFragment[..<qIdx])
        existingQuery = String(withoutFragment[withoutFragment.index(after: qIdx)...])
    }

    var order: [String] = []
    var merged: [String: String] = [:]
    func set(_ key: String, _ value: String) {
        if merged[key] == nil { order.append(key) }
        merged[key] = value
    }

    if !existingQuery.isEmpty {
        for pair in existingQuery.split(separator: "&", omittingEmptySubsequences: true) {
            let raw = String(pair)
            if let eq = raw.firstIndex(of: "=") {
                let key = decodeComponent(String(raw[..<eq]))
                let value = decodeComponent(String(raw[raw.index(after: eq)...]))
                set(key, value)
            } else {
                set(decodeComponent(raw), "")
            }
        }
    }

    if !deviceType.isEmpty {
        set("device_type", deviceType)
    }

    for (key, value) in config.toQueryParameters() {
        set(key, value)
    }

    let query = order
        .map { "\(encodeComponent($0))=\(encodeComponent(merged[$0]!))" }
        .joined(separator: "&")

    return query.isEmpty ? "\(path)\(fragment)" : "\(path)?\(query)\(fragment)"
}

/// Percent-encode a query component but keep commas literal.
private func encodeComponent(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-_.!~*'(),")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}

private func decodeComponent(_ value: String) -> String {
    value.removingPercentEncoding ?? value
}
