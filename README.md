# OddittSDK (iOS)

[![CI](https://github.com/Odditt-Betflow/odditt-ios-sdk/actions/workflows/ci.yaml/badge.svg)](https://github.com/Odditt-Betflow/odditt-ios-sdk/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Thin embed SDK for the Odditt betting widget. Drop the widget into your iOS app
with one `OddittWidget` (SwiftUI) or `OddittWidgetView` (UIKit), pass embedding
params as typed config, and receive typed post-back signals. Odditt renders the
widget and ships updates — you change nothing when content is added or removed.

Built on `WKWebView`. iOS 13+.

## Install

### Swift Package Manager

```swift
.package(url: "https://github.com/Odditt-Betflow/odditt-ios-sdk.git", branch: "main")
```

Then add `"OddittSDK"` to your target's dependencies. `branch: "main"` tracks the
latest published SDK; use `.revision("<sha>")` to pin a reproducible build.

In Xcode: **File → Add Package Dependencies**, paste the repo URL, and choose
**Dependency Rule → Branch → `main`**.

### CocoaPods

Point the pod straight at the repo:

```ruby
pod 'OddittSDK', :git => 'https://github.com/Odditt-Betflow/odditt-ios-sdk.git', :branch => 'main'
```

### From CocoaPods trunk (once published)

```ruby
pod 'OddittSDK', '~> 0.1'
```

## Usage

### SwiftUI

```swift
import SwiftUI
import OddittSDK

struct Feed: View {
    var body: some View {
        ScrollView {
            OddittWidget(
                baseUrl: "https://demo.odditt.com", // required, no default
                config: OddittWidgetConfig(
                    country: "US",
                    oddsFormat: "american",
                    colorMode: "dark",         // dark | light
                    layoutMode: "carousel",    // carousel | feed
                    widgetMode: "operator",    // operator | affiliate | clean
                    productMode: "sportsbook", // sportsbook | dfs | prediction_market
                    sportIds: [1, 2],
                    extraParams: ["includeAltLines": true]
                ),
                onBetClicked: { signal in
                    // wire your betslip / deeplink / order flow
                    print(signal.betDescription ?? "", signal.betOddsAmerican ?? 0)
                },
                onSignal: { print("signal: \($0)") }
            )
        }
    }
}
```

### UIKit

```swift
let widget = OddittWidgetView(autoHeight: true)
widget.onBetClicked = { signal in /* ... */ }
widget.onSignal = { signal in print(signal) }
widget.load(baseUrl: "https://demo.odditt.com", config: OddittWidgetConfig(country: "US"))
view.addSubview(widget)
// pin widget.leadingAnchor/trailingAnchor/topAnchor; height is self-sizing.
```

### Config → URL

`OddittWidgetConfig.toQueryParameters()` serializes with the widget's coercion
rules: `Bool → "true"/"false"`, `[Int]/[String] → comma-joined`, `nil` omitted.
`buildWidgetUrl(baseUrl:config:)` composes the final URL. The widget detects a
genuine native embed via the injected `OddittBridge` channel (no URL flag).

`buildWidgetUrl` also seeds `device_type=ios` so the widget's affiliate click-out
resolves the right deep link — inside a `WKWebView` its user-agent fallback is
unreliable and degrades to the desktop URL. Override with
`extraParams: ["device_type": "desktop"]` or the `deviceType:` argument.

### Signals

Every post-back is decoded into a typed `OddittSignal` enum: `widgetReady`,
`widgetEmpty`, `widgetError`, `betClicked`, `pageLoaded`, `filterChanged`,
`graphExpanded`, `graphCollapsed`, `contentHeightChanged` and `externalUrl`
(both SDK-synthesized), `unknown` (forward-compat). Use `onSignal` for all, or
the granular `onReady` / `onEmpty` / `onError` / `onBetClicked` /
`onExternalUrl` callbacks.

### Affiliate click-outs

In `widgetMode=affiliate` the widget opens tracked deep links with
`window.open(url, "_blank")`, which a `WKWebView` cannot honour. The SDK
intercepts those (plus `target="_blank"` anchors and custom-scheme navigations)
and opens them with `UIApplication.shared.open`.

Set `onExternalUrl` to take over — present an `SFSafariViewController` yourself,
or attach your own tracking first:

```swift
OddittWidget(
    baseUrl: "https://demo.odditt.com",
    onExternalUrl: { url, _ in presentSafari(url) }
)
```

### Auto-height

There is no widget height signal, so the SDK injects a `ResizeObserver` that
reports `document.body.scrollHeight` over the bridge; the view sizes itself to
content (clamped by `minHeight`/`maxHeight`, default `120`/`5000`). Pass
`autoHeight: false` to manage height yourself (the WebView then fills its bounds).

## Example

A SwiftUI example lives in [`Example/`](Example). Generate its Xcode project with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`cd Example && xcodegen`) and
run against your widget host (`http://localhost:3000` on the simulator, or a
deployed URL).

## Scope

Embed only. No REST/API client, no server-driven UI.
