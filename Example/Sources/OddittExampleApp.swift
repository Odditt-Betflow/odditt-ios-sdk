import OddittSDK
import SwiftUI

@main
struct OddittExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    // The iOS simulator can reach the host machine at localhost. Swap for a
    // deployed URL when testing remotely.
    private let baseUrl = "http://localhost:3000"

    @State private var log: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Odditt SDK example")
                .font(.headline)
                .padding()

            ScrollView {
                OddittWidget(
                    baseUrl: baseUrl,
                    config: OddittWidgetConfig(
                        country: "US",
                        colorMode: "dark",
                        layoutMode: "feed",
                        widgetMode: "operator"
                    ),
                    onSignal: record
                )
            }

            Text("Signal log")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            List(Array(log.enumerated()), id: \.offset) { _, line in
                Text(line).font(.system(.caption, design: .monospaced))
            }
            .frame(maxHeight: 180)
        }
    }

    private func record(_ signal: OddittSignal) {
        switch signal {
        case .betClicked:
            log.insert("BET_CLICKED: \(signal.betDescription ?? "") @ \(signal.betOddsAmerican ?? 0)", at: 0)
        case .contentHeightChanged:
            break
        default:
            log.insert(String(describing: signal), at: 0)
        }
    }
}
