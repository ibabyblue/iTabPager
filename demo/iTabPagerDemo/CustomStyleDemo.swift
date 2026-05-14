import SwiftUI
import ITabPager

struct CustomStyleDemo: View {
    let tabs = ["全部", "视频", "图文", "直播"]
    @State private var selection = "全部"

    private var customStyle: ITabPagerStyle {
        var s = ITabPagerStyle()
        s.selectedFont = .system(size: 15, weight: .semibold)
        s.unselectedFont = .system(size: 15, weight: .regular)
        s.selectedColor = .orange
        s.unselectedColor = .secondary
        s.indicatorColor = .orange
        s.indicatorWidthRatio = 0.7
        s.indicatorHeight = 2
        s.indicatorSpacing = 6
        s.tabSpacing = 24
        return s
    }

    var body: some View {
        ITabPager(
            tabs: tabs,
            selection: $selection,
            alignment: .center,
            style: customStyle,
            content: { tab in
                List(0..<25, id: \.self) { i in
                    Label("\(tab) · 第 \(i + 1) 项", systemImage: icon(for: tab))
                }
                .listStyle(.plain)
            },
            tabTitle: { $0 }
        )
        .navigationTitle("Custom Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func icon(for tab: String) -> String {
        switch tab {
        case "视频": return "play.rectangle"
        case "图文": return "doc.richtext"
        case "直播": return "antenna.radiowaves.left.and.right"
        default: return "square.grid.2x2"
        }
    }
}
