import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(viewModel: viewModel)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        Group {
            if let data = viewModel.usageData {
                if data.hasUnifiedLimits {
                    let remaining = 100 - data.fiveHourPercent
                    HStack(spacing: 2) {
                        Image(systemName: batteryIcon(remaining))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(batteryColor(remaining))
                        Text("\(remaining)%")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(batteryColor(remaining))
                    }
                } else if data.hasStandardLimits {
                    let remaining = 100 - data.requestsUsedPercent
                    HStack(spacing: 2) {
                        Image(systemName: batteryIcon(remaining))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(batteryColor(remaining))
                        Text("\(remaining)%")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(batteryColor(remaining))
                    }
                } else {
                    Image(systemName: "battery.0")
                }
            } else if viewModel.isLoading {
                Image(systemName: "arrow.triangle.2.circlepath")
            } else if viewModel.errorMessage != nil {
                Image(systemName: "exclamationmark.triangle")
            } else {
                Image(systemName: "key")
            }
        }
        .task {
            viewModel.startPolling()
        }
    }

    private func batteryIcon(_ remaining: Int) -> String {
        switch remaining {
        case 76...100: return "battery.100"
        case 51...75:  return "battery.75"
        case 26...50:  return "battery.50"
        case 1...25:   return "battery.25"
        default:       return "battery.0"
        }
    }

    private func batteryColor(_ remaining: Int) -> Color {
        switch remaining {
        case 51...100: return .green
        case 21...50:  return .yellow
        default:       return .red
        }
    }
}
