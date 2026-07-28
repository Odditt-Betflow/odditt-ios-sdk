#if canImport(SwiftUI) && canImport(UIKit) && canImport(WebKit)
import SwiftUI

/// A SwiftUI drop-in embed of the Odditt betting widget.
///
/// Wraps ``OddittWidgetView``. With `autoHeight` (default) the view sizes itself
/// to the widget's reported content height; wrap it in a `ScrollView` if the
/// content can exceed the screen. Forwards post-back signals via `onSignal` plus
/// optional granular callbacks.
@available(iOS 13.0, *)
public struct OddittWidget: UIViewRepresentable {
    private let baseUrl: String
    private let config: OddittWidgetConfig
    private let autoHeight: Bool
    private let onSignal: ((OddittSignal) -> Void)?
    private let onReady: (() -> Void)?
    private let onEmpty: (() -> Void)?
    private let onError: ((_ message: String, _ status: Int?, _ phase: String) -> Void)?
    private let onBetClicked: ((OddittSignal) -> Void)?
    private let onExternalUrl: ((_ url: String, _ target: String) -> Void)?

    public init(
        baseUrl: String,
        config: OddittWidgetConfig = OddittWidgetConfig(),
        autoHeight: Bool = true,
        onSignal: ((OddittSignal) -> Void)? = nil,
        onReady: (() -> Void)? = nil,
        onEmpty: (() -> Void)? = nil,
        onError: ((_ message: String, _ status: Int?, _ phase: String) -> Void)? = nil,
        onBetClicked: ((OddittSignal) -> Void)? = nil,
        onExternalUrl: ((_ url: String, _ target: String) -> Void)? = nil
    ) {
        self.baseUrl = baseUrl
        self.config = config
        self.autoHeight = autoHeight
        self.onSignal = onSignal
        self.onReady = onReady
        self.onEmpty = onEmpty
        self.onError = onError
        self.onBetClicked = onBetClicked
        self.onExternalUrl = onExternalUrl
    }

    public func makeUIView(context _: Context) -> OddittWidgetView {
        let view = OddittWidgetView(autoHeight: autoHeight)
        view.onSignal = onSignal
        view.onReady = onReady
        view.onEmpty = onEmpty
        view.onError = onError
        view.onBetClicked = onBetClicked
        view.onExternalUrl = onExternalUrl
        view.load(baseUrl: baseUrl, config: config)
        return view
    }

    public func updateUIView(_ view: OddittWidgetView, context _: Context) {
        // Re-embed in place when the base URL or serialized query changes.
        view.load(baseUrl: baseUrl, config: config)
    }
}
#endif
