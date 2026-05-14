import SwiftUI
import ITabPager

enum BasicTab: String, CaseIterable {
    case recommended = "推荐"
    case hot = "热门"
    case latest = "最新"
}

struct BasicDemo: View {
    @State private var selection: BasicTab = .recommended

    var body: some View {
        ITabPager(
            tabs: BasicTab.allCases,
            selection: $selection,
            content: { tab in
                List(0..<30, id: \.self) { i in
                    Text("\(tab.rawValue) · 第 \(i + 1) 条")
                }
                .listStyle(.plain)
            },
            tabTitle: { $0.rawValue }
        )
        .navigationTitle("Basic Demo")
        .navigationBarTitleDisplayMode(.inline)
    }
}
