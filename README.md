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
.package(url: "https://github.com/Odditt-Betflow/odditt-ios-sdk.git", from: "0.1.0")
```

Then add `"OddittSDK"` to your target's dependencies.

### CocoaPods

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
                    colorMode: "dark",       // dark | light
                    layoutMode: "carousel",  // carousel | feed
                    widgetMode: "operator",  // operator | affiliate | prediction-market
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

### Signals

Every post-back is decoded into a typed `OddittSignal` enum: `widgetReady`,
`widgetEmpty`, `widgetError`, `betClicked`, `pageLoaded`, `filterChanged`,
`graphExpanded`, `graphCollapsed`, `contentHeightChanged` (SDK-synthesized),
`unknown` (forward-compat). Use `onSignal` for all, or the granular `onReady` /
`onEmpty` / `onError` / `onBetClicked` callbacks.

### Auto-height

There is no widget height signal, so the SDK injects a `ResizeObserver` that
reports `document.body.scrollHeight` over the bridge; the view sizes itself to
content (clamped by `minHeight`/`maxHeight`, default `120`/`5000`). Pass
`autoHeight: false` to manage height yourself (the WebView then fills its bounds).

## Deployment requirement

The bridge injects a `message` listener into the WebView. In a WebView there is
no iframe, so the widget's `window.parent.postMessage(data, targetOrigin)`
dispatches to the WebView's own `window` — this only reaches the listener when
`targetOrigin` is `"*"`. **Deploy the widget with `NEXT_PUBLIC_PARENT_ORIGIN="*"`**
(the default) and do not set the `parentOrigin` embed param (the SDK never emits
it). If the widget is pinned to a specific origin, no signals are received.

## Example

A SwiftUI example lives in [`Example/`](Example). Generate its Xcode project with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`cd Example && xcodegen`) and
run against your widget host (`http://localhost:3000` on the simulator, or a
deployed URL).

## Scope

Embed only. No REST/API client, no server-driven UI.
