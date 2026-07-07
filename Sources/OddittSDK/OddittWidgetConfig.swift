import Foundation

/// Configuration for an embedded Odditt widget.
///
/// Holds the embedding parameters an operator commonly sets as typed fields,
/// plus an ``extraParams`` escape hatch for the long tail of ~80 query params
/// the widget supports.
///
/// ``toQueryParameters()`` applies the same coercion rules the widget's URL
/// parser expects: booleans become `"true"`/`"false"`, `Int`/`String` arrays
/// become comma-joined strings, and `nil` fields are omitted entirely.
public struct OddittWidgetConfig {
    /// ISO country code, e.g. `US`.
    public var country: String?
    /// Sub-region, e.g. `NY`.
    public var region: String?
    /// BCP-47 language tag, e.g. `en-US`.
    public var lang: String?
    /// `american` | `decimal` | `fractional` | `multiplier` | `probability`.
    public var oddsFormat: String?
    /// Display currency, e.g. `USD`.
    public var currency: String?
    /// `dark` | `light`.
    public var colorMode: String?
    /// `carousel` | `feed`.
    public var layoutMode: String?
    /// Remote theme preset name.
    public var preset: String?
    /// `operator` | `affiliate` | `prediction-market` etc.
    public var widgetMode: String?
    /// Product mode passed through to the backend.
    public var productMode: String?
    /// Restrict to parlay flows.
    public var parlay: Bool?
    /// Sport id allowlist (serialized as `sportIds=1,2,3`).
    public var sportIds: [Int]?
    /// League id allowlist (serialized as `leagueIds=10,20`).
    public var leagueIds: [Int]?
    /// Page background color (hex, with or without leading `#`).
    public var bg: String?
    /// Use cartoon player images.
    public var useCartoonImages: Bool?
    /// Include alternate lines.
    public var includeAltLines: Bool?
    /// Any additional widget query params not modeled above. Values may be
    /// `String`, `Bool`, `Int`, `Double`, `[Int]` or `[String]`; they are coerced
    /// with the same rules as the typed fields. Keys here win over typed fields.
    /// `parentOrigin` is always dropped.
    public var extraParams: [String: Any]

    public init(
        country: String? = nil,
        region: String? = nil,
        lang: String? = nil,
        oddsFormat: String? = nil,
        currency: String? = nil,
        colorMode: String? = nil,
        layoutMode: String? = nil,
        preset: String? = nil,
        widgetMode: String? = nil,
        productMode: String? = nil,
        parlay: Bool? = nil,
        sportIds: [Int]? = nil,
        leagueIds: [Int]? = nil,
        bg: String? = nil,
        useCartoonImages: Bool? = nil,
        includeAltLines: Bool? = nil,
        extraParams: [String: Any] = [:]
    ) {
        self.country = country
        self.region = region
        self.lang = lang
        self.oddsFormat = oddsFormat
        self.currency = currency
        self.colorMode = colorMode
        self.layoutMode = layoutMode
        self.preset = preset
        self.widgetMode = widgetMode
        self.productMode = productMode
        self.parlay = parlay
        self.sportIds = sportIds
        self.leagueIds = leagueIds
        self.bg = bg
        self.useCartoonImages = useCartoonImages
        self.includeAltLines = includeAltLines
        self.extraParams = extraParams
    }

    /// Serialize to the widget's query-parameter map. Omits `nil` values.
    ///
    /// `parentOrigin` is intentionally never emitted — the WebView bridge relies
    /// on the widget posting with `targetOrigin: "*"`.
    public func toQueryParameters() -> [String: String] {
        var params: [String: String] = [:]

        func put(_ key: String, _ value: Any?) {
            if let coerced = OddittWidgetConfig.coerce(value) {
                params[key] = coerced
            }
        }

        put("country", country)
        put("region", region)
        put("lang", lang)
        put("oddsFormat", oddsFormat)
        put("currency", currency)
        put("colorMode", colorMode)
        put("layoutMode", layoutMode)
        put("preset", preset)
        put("widgetMode", widgetMode)
        put("productMode", productMode)
        put("parlay", parlay)
        put("sportIds", sportIds)
        put("leagueIds", leagueIds)
        put("bg", bg)
        put("useCartoonImages", useCartoonImages)
        put("includeAltLines", includeAltLines)

        for (key, value) in extraParams {
            if key == "parentOrigin" { continue }
            put(key, value)
        }

        return params
    }

    /// Coerce a single value to its query-string form, or `nil` to omit it.
    static func coerce(_ value: Any?) -> String? {
        guard let value = value, !(value is NSNull) else { return nil }
        if let b = value as? Bool { return b ? "true" : "false" }
        if let s = value as? String { return s.isEmpty ? nil : s }
        if let i = value as? Int { return String(i) }
        if let d = value as? Double { return String(d) }
        if let arr = value as? [Any] {
            let parts = arr.compactMap { element -> String? in
                element is NSNull ? nil : String(describing: element)
            }
            let joined = parts.joined(separator: ",")
            return joined.isEmpty ? nil : joined
        }
        return String(describing: value)
    }
}
