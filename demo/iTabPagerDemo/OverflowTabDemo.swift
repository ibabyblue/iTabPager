import SwiftUI
import iTabPager

struct OverflowTabDemo: View {
    let tabs = ["关注", "推荐", "热榜", "游戏", "影视", "音乐", "体育", "科技", "财经", "汽车", "美食", "旅游", "时尚", "健康", "教育"]
    @State private var selection = "推荐"

    var body: some View {
        ITabPager(
            tabs: tabs,
            selection: $selection,
            content: { tab in
                List(0..<40, id: \.self) { i in
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color(for: tab))
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(tab) · 条目 \(i + 1)")
                                .font(.headline)
                            Text("副标题内容示例文字")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            },
            tabTitle: { $0 }
        )
        .navigationTitle("Overflow Demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func color(for tab: String) -> Color {
        let colors: [Color] = [.blue, .red, .orange, .green, .purple, .pink, .teal, .indigo]
        let index = tabs.firstIndex(of: tab) ?? 0
        return colors[index % colors.count].opacity(0.3)
    }
}
