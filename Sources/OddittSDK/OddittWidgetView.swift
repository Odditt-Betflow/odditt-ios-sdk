#if canImport(UIKit) && canImport(WebKit)
import UIKit
import WebKit

/// Delegate for post-back signals from an ``OddittWidgetView``.
public protocol OddittWidgetViewDelegate: AnyObject {
    /// Fires for every decoded signal (including content-height and unknown).
    func oddittWidget(_ view: OddittWidgetView, didReceive signal: OddittSignal)
}

/// A drop-in `UIView` embed of the Odditt betting widget.
///
/// Loads the widget from a base URL with a config serialized as query params,
/// installs the JS bridge over `WKWebView`, and surfaces post-back signals via
/// ``delegate`` plus optional closures. With ``autoHeight`` (default) the view
/// sizes itself to the widget's reported content height, clamped by
/// ``minHeight``/``maxHeight``.
public final class OddittWidgetView: UIView, WKScriptMessageHandler {
    /// Receives every decoded signal.
    public weak var delegate: OddittWidgetViewDelegate?

    /// Fires for every signal (including content-height and unknown signals).
    public var onSignal: ((OddittSignal) -> Void)?
    /// Convenience closure for `WIDGET_READY`.
    public var onReady: (() -> Void)?
    /// Convenience closure for `WIDGET_EMPTY`.
    public var onEmpty: (() -> Void)?
    /// Convenience closure for `WIDGET_ERROR`.
    public var onError: ((_ message: String, _ status: Int?, _ phase: String) -> Void)?
    /// Convenience closure for `BET_CLICKED`.
    public var onBetClicked: ((OddittSignal) -> Void)?

    /// When true (default), the view sizes itself to the widget's reported height.
    public let autoHeight: Bool
    /// Lower clamp for the auto-sized height. Default 120.
    public var minHeight: CGFloat = 120
    /// Upper clamp for the auto-sized height. Default 5000.
    public var maxHeight: CGFloat = 5000

    private let webView: WKWebView
    private var heightConstraint: NSLayoutConstraint?
    private var loadedUrl: String?

    /// Creates the view. Call ``load(baseUrl:config:)`` to embed the widget.
    /// - Parameters:
    ///   - autoHeight: size to content height (default) or fill the parent.
    ///   - initialHeight: height used before the first content-height signal.
    public init(autoHeight: Bool = true, initialHeight: CGFloat = 400) {
        self.autoHeight = autoHeight

        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(source: OddittBridge.shimScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        controller.addUserScript(
            WKUserScript(source: OddittBridge.bridgeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(frame: .zero)

        // Weak proxy avoids the message-handler retain cycle.
        controller.add(WeakScriptMessageHandler(self), name: OddittBridge.channelName)

        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = !autoHeight
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        if autoHeight {
            let constraint = heightAnchor.constraint(equalToConstant: initialHeight)
            constraint.priority = .defaultHigh
            constraint.isActive = true
            heightConstraint = constraint
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Load (or re-embed) the widget. Calling again with a different base URL or
    /// config reloads in place; an unchanged URL is a no-op (so repeated SwiftUI
    /// updates don't reset the widget).
    public func load(baseUrl: String, config: OddittWidgetConfig = OddittWidgetConfig()) {
        let urlString = buildWidgetUrl(baseUrl: baseUrl, config: config)
        guard urlString != loadedUrl, let url = URL(string: urlString) else { return }
        loadedUrl = urlString
        webView.load(URLRequest(url: url))
    }

    // MARK: WKScriptMessageHandler

    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let raw = message.body as? String, let signal = parseSignal(raw) else { return }

        if case let .contentHeightChanged(height, _) = signal, autoHeight {
            let clamped = min(max(CGFloat(height), minHeight), maxHeight)
            if heightConstraint?.constant != clamped {
                heightConstraint?.constant = clamped
                invalidateIntrinsicContentSize()
            }
        }

        onSignal?(signal)
        delegate?.oddittWidget(self, didReceive: signal)

        switch signal {
        case .widgetReady:
            onReady?()
        case .widgetEmpty:
            onEmpty?()
        case let .widgetError(message, status, phase, _):
            onError?(message, status, phase)
        case .betClicked:
            onBetClicked?(signal)
        default:
            break
        }
    }
}

/// Breaks the strong retain cycle `WKUserContentController` → handler → view.
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}
#endif
