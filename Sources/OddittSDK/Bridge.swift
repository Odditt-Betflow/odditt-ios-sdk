import Foundation

/// The injected JS bridge that funnels widget post-back messages to native.
public enum OddittBridge {
    /// The name of the `WKScriptMessageHandler` (and the `window` global).
    public static let channelName = "OddittBridge"

    /// Injected at document-start: exposes a `window.OddittBridge` global with a
    /// `postMessage(string)` method that routes to the WKWebView message handler.
    /// The widget auto-detects a native embed by the presence of this global.
    public static let shimScript = """
    (function () {
      if (!window.OddittBridge) {
        window.OddittBridge = {
          postMessage: function (m) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(channelName)) {
              window.webkit.messageHandlers.\(channelName).postMessage(m);
            }
          }
        };
      }
    })();
    """

    /// Injected at document-end. Verbatim port of the Flutter SDK bridge script.
    /// Forwards every `window` `message` event with a `.type` to the bridge, and
    /// reports content height via a `ResizeObserver` under `__CONTENT_HEIGHT__`.
    /// Guarded by `__oddittBridgeInstalled__` so repeated injection is a no-op.
    public static let bridgeScript = """
    (function () {
      if (window.__oddittBridgeInstalled__) return;
      window.__oddittBridgeInstalled__ = true;

      function send(obj) {
        try {
          \(channelName).postMessage(JSON.stringify(obj));
        } catch (e) {}
      }

      window.addEventListener('message', function (event) {
        if (event && event.data && typeof event.data === 'object' && event.data.type) {
          send(event.data);
        }
      });

      var lastHeight = -1;
      function reportHeight() {
        var h = Math.ceil(document.body ? document.body.scrollHeight : 0);
        if (h > 0 && h !== lastHeight) {
          lastHeight = h;
          send({ type: '__CONTENT_HEIGHT__', payload: { height: h }, timestamp: Date.now() });
        }
      }

      if (window.ResizeObserver && document.body) {
        new ResizeObserver(reportHeight).observe(document.body);
      }
      reportHeight();
    })();
    """
}
