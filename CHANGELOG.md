# Changelog

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
