# Changelog

## Unreleased

- Affiliate click-outs now work. The injected bridge intercepts
  `window.open(url, "_blank")` and `target="_blank"` anchors, and a
  `WKNavigationDelegate` policy hook catches off-origin navigations and
  custom-scheme deep links; both surface as `OddittSignal.externalUrl` and open
  via `UIApplication.shared.open` unless the host sets `onExternalUrl`.
- `buildWidgetUrl` seeds `device_type=ios` so the widget resolves the right
  affiliate deep link instead of falling back to WKWebView user-agent sniffing.
  Override with the `deviceType:` argument or `extraParams["device_type"]`.
- Docs: install instructions target `main` (no tags are published yet), added the
  CocoaPods `:git` form, corrected the `widgetMode` values
  (`operator | affiliate | clean`; `prediction_market` is a `productMode`), and
  dropped the stale `NEXT_PUBLIC_PARENT_ORIGIN="*"` deployment requirement — the
  widget posts to `window.OddittBridge` directly, so the target origin no longer
  applies.

## 0.1.0

Initial release.

- `OddittWidgetView` (UIKit) and `OddittWidget` (SwiftUI) — drop-in embed of the
  Odditt betting widget in a managed `WKWebView`, with `autoHeight` sizing and
  re-embed on config change.
- `OddittWidgetConfig` + `buildWidgetUrl` — typed embedding parameters plus an
  `extraParams` escape hatch; serializes with the widget's query-param coercion
  rules.
- `OddittSignal` — enum modeling every post-back signal (`widgetReady`,
  `widgetEmpty`, `widgetError`, `betClicked`, `pageLoaded`, `filterChanged`,
  `graphExpanded`, `graphCollapsed`, `contentHeightChanged`, `unknown`) with
  `parseSignal` and `betOddsAmerican` / `betDescription` accessors.
- Native bridge (`OddittBridge`) injected into the WebView so the widget's
  post-back messages reach native without an iframe.
