#if canImport(UIKit)
import SwiftUI

// MARK: - ITabPager

public struct ITabPager<Tab: Hashable, Content: View>: View {

    // MARK: Public Properties

    let tabs: [Tab]
    @Binding var selection: Tab
    var alignment: HorizontalAlignment
    var style: ITabPagerStyle
    let content: (Tab) -> Content
    let tabTitle: (Tab) -> String

    // MARK: Private State

    @State private var progress: CGFloat = 0
    @State private var tabFrames: [AnyHashable: CGRect] = [:]
    @State private var containerWidth: CGFloat = 0
    @State private var isInitialized = false

    // MARK: Init

    public init(
        tabs: [Tab],
        selection: Binding<Tab>,
        alignment: HorizontalAlignment = .leading,
        style: ITabPagerStyle = .init(),
        @ViewBuilder content: @escaping (Tab) -> Content,
        tabTitle: @escaping (Tab) -> String
    ) {
        self.tabs = tabs
        self._selection = selection
        self.alignment = alignment
        self.style = style
        self.content = content
        self.tabTitle = tabTitle
    }

    // MARK: Body

    public var body: some View {
        if tabs.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                tabStripView
                PagerScrollView(
                    tabs: tabs,
                    selection: $selection,
                    progress: $progress,
                    content: content
                )
            }
            .onAppear {
                // 初始化 progress，避免出现时指示器在 page 0
                if let index = tabs.firstIndex(of: selection) {
                    progress = CGFloat(index)
                }
            }
            .onChange(of: selection) { _, newValue in
                // selection 不在 tabs 里时修正
                if !tabs.contains(newValue), let first = tabs.first {
                    selection = first
                }
            }
        }
    }
}

// MARK: - Tab Strip

extension ITabPager {

    private var initialScrollAnchor: UnitPoint {
        switch alignment {
        case .trailing: return .trailing
        case .center:   return .center
        default:        return .leading
        }
    }

    private var tabStripView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: style.tabSpacing) {
                    ForEach(tabs, id: \.self) { tab in
                        tabButton(tab)
                            .id(tab)
                    }
                }
                .frame(
                    minWidth: containerWidth,
                    alignment: Alignment(horizontal: alignment, vertical: .center)
                )
                .coordinateSpace(name: "tabPagerStrip")
                .onPreferenceChange(TabFrameKey.self) { frames in
                    tabFrames = frames
                    if !isInitialized && !frames.isEmpty {
                        Task { @MainActor in isInitialized = true }
                    }
                }
                .overlay(alignment: .bottom) {
                    indicatorView
                }
                .onAppear {
                    Task { @MainActor in
                        proxy.scrollTo(selection, anchor: initialScrollAnchor)
                    }
                }
                .onChange(of: selection) { _, newValue in
                    Task { @MainActor in
                        withAnimation(.spring(duration: 0.25)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
        .defaultScrollAnchor(initialScrollAnchor)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { containerWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in containerWidth = w }
            }
        )
    }

    @ViewBuilder
    private func tabButton(_ tab: Tab) -> some View {
        let index = tabs.firstIndex(of: tab) ?? 0
        // 滑动过程中从 progress 连续插值选中权重：当前 tab 正好对齐时为 1，偏移 1 页后为 0
        let fraction = max(0.0, 1.0 - abs(progress - CGFloat(index)))
        ZStack {
            // 占位用 selectedFont，保持 tab 宽度在选中/未选中时一致
            Text(tabTitle(tab))
                .font(style.selectedFont)
                .hidden()
            // 未选中底层
            Text(tabTitle(tab))
                .font(style.unselectedFont)
                .foregroundStyle(style.unselectedColor)
            // 选中层，随 fraction 淡入
            Text(tabTitle(tab))
                .font(style.selectedFont)
                .foregroundStyle(style.selectedColor)
                .opacity(fraction)
        }
        .padding(.bottom, style.indicatorHeight + style.indicatorSpacing)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.25)) { selection = tab }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: TabFrameKey.self,
                    value: [AnyHashable(tab): geo.frame(in: .named("tabPagerStrip"))]
                )
            }
        )
    }

    private var indicatorView: some View {
        // 用 progress 在相邻 tab frame 之间插值，实现跟随手指效果
        let lo = max(0, min(Int(progress), tabs.count - 1))
        let hi = min(tabs.count - 1, lo + 1)
        let fraction = progress - CGFloat(lo)

        let fromFrame = tabFrames[AnyHashable(tabs[lo])] ?? .zero
        let toFrame   = tabFrames[AnyHashable(tabs[hi])] ?? fromFrame

        let iw     = lerp(fromFrame.width, toFrame.width, fraction) * style.indicatorWidthRatio
        let midX   = lerp(fromFrame.midX, toFrame.midX, fraction)
        let offsetX = max(0, midX - iw / 2)

        return Capsule()
            .fill(style.indicatorColor)
            .frame(width: max(0, iw), height: style.indicatorHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: offsetX)
            // progress 变化不加动画——由 scrollViewDidScroll 高频回调驱动，本身就是连续的
            .animation(isInitialized ? .spring(duration: 0.25) : nil, value: tabFrames.keys.count)
    }
}

#endif
