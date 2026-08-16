import DrawerKit
import SwiftUI

struct DemoRootView: View {
    @State private var isDrawerOpen = ProcessInfo.processInfo.arguments.contains("-drawer-open")
    @State private var selectedSection = "Inbox"
    @State private var underlyingTapCount = 0

    var body: some View {
        Drawer(isOpen: $isDrawerOpen, configuration: configuration) {
            navigationPanel
        } content: {
            mainContent
        }
        .tint(.indigo)
        .preferredColorScheme(preferredColorScheme)
    }

    private var configuration: DrawerConfiguration {
        var configuration = DrawerConfiguration()
        configuration.width = 310
        configuration.backgroundColor = Color(uiColor: .secondarySystemBackground)
        configuration.contentCornerRadius = 48
        configuration.contentDimOpacity = 0.04
        return configuration
    }

    private var navigationPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Label("DrawerKit", systemImage: "sidebar.leading")
                    .font(.title2.bold())
                    .padding(.bottom, 18)

                ForEach(["Inbox", "Today", "Saved", "Archive"], id: \.self) { section in
                    Button {
                        selectedSection = section
                        isDrawerOpen = false
                    } label: {
                        Label(section, systemImage: symbol(for: section))
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                selectedSection == section ? Color.indigo.opacity(0.14) : .clear,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("drawer.\(section.lowercased())")
                }

                Divider()
                    .padding(.vertical, 12)

                ForEach(1...12, id: \.self) { index in
                    Label("Collection \(index)", systemImage: "square.grid.2x2")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 24)
        }
        .accessibilityIdentifier("drawer.panel")
    }

    private var mainContent: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    Text(selectedSection)
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("main.title")
                        .accessibilityAddTraits(.isHeader)

                    headerCard

                    ForEach(1...10, id: \.self) { index in
                        HStack(spacing: 14) {
                            Image(
                                systemName: index.isMultiple(of: 2) ? "doc.text.fill" : "sparkles"
                            )
                            .foregroundStyle(.indigo)
                            .frame(width: 34, height: 34)
                            .background(
                                .indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(itemTitle(index))
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("A focused example row for the DrawerKit demo.")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityHidden(true)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(18)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isDrawerOpen = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("Open navigation")
                    .accessibilityIdentifier("drawer.open")
                }
            }
        }
        .accessibilityIdentifier("main.content")
    }

    private var headerCard: some View {
        Button {
            underlyingTapCount += 1
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text("A drawer that feels at home in SwiftUI")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap count: \(underlyingTapCount)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("main.tapCount")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background(
                LinearGradient(
                    colors: [.indigo, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("main.action")
    }

    private var preferredColorScheme: ColorScheme? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-light") { return .light }
        if arguments.contains("-dark") { return .dark }
        return nil
    }

    private func symbol(for section: String) -> String {
        switch section {
        case "Inbox": "tray.full"
        case "Today": "sun.max"
        case "Saved": "bookmark"
        default: "archivebox"
        }
    }

    private func itemTitle(_ index: Int) -> String {
        [
            "Explore the example app",
            "Tune the configuration",
            "Try edge-to-open",
            "Swipe the content to close",
            "Switch to dark appearance",
        ][(index - 1) % 5]
    }
}
