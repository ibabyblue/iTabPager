# iTabPager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 `TabPager`——一个 Tab bar + 横向翻页内容容器联动的 Swift Package，指示器实时跟随手指，调用者只需提供 tab 数组和内容 View。

**Architecture:** 公开类型仅 `TabPager`（SwiftUI View）和 `TabPagerStyle`。内容容器用 `UIViewControllerRepresentable` 封装 `UIScrollView`（`isPagingEnabled = true`），delegate 实时回传 `progress: CGFloat`；tab bar 是 `TabPager` 的私有子视图，读 `progress` 做插值驱动指示器。只保活当前页 ±1 页的 `UIHostingController`（滑动窗口懒加载）。

**Tech Stack:** Swift 6.2, SwiftUI, UIKit (UIScrollView + UIHostingController), iOS 17+, XCTest

---

## 文件地图

| 文件 | 职责 |
|---|---|
| `Package.swift` | 添加 `.iOS(.v17)` platform 约束 |
| `Sources/iTabPager/Internal/Lerp.swift` | `lerp(_:_:_:)` 工具函数（internal） |
| `Sources/iTabPager/Internal/TabFrameKey.swift` | `TabFrameKey: PreferenceKey`，收集 tab 的 CGRect（internal） |
| `Sources/iTabPager/TabPagerStyle.swift` | `TabPagerStyle` 样式配置（public） |
| `Sources/iTabPager/PagerScrollView.swift` | `PagerScrollView: UIViewControllerRepresentable` + `PagerViewController: UIViewController`（internal） |
| `Sources/iTabPager/TabPager.swift` | `TabPager: View`（public），含 `tabStripView` 私有扩展 |
| `Tests/iTabPagerTests/iTabPagerTests.swift` | `lerp`、selection 修正逻辑的单元测试 |

---

## Task 1: Package.swift + 目录结构

**Files:**
- Modify: `Package.swift`
- Create: `Sources/iTabPager/Internal/Lerp.swift`（空文件占位）
- Create: `Sources/iTabPager/Internal/TabFrameKey.swift`（空文件占位）
- Create: `Sources/iTabPager/TabPagerStyle.swift`（空文件占位）
- Create: `Sources/iTabPager/PagerScrollView.swift`（空文件占位）
- Create: `Sources/iTabPager/TabPager.swift`（空文件占位）

- [ ] **Step 1: 更新 Package.swift，添加 iOS 17 约束**

```swift
// Package.swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "iTabPager",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "iTabPager", targets: ["iTabPager"]),
    ],
    targets: [
        .target(name: "iTabPager"),
        .testTarget(name: "iTabPagerTests", dependencies: ["iTabPager"]),
    ]
)
```

- [ ] **Step 2: 创建 Internal 目录和占位文件**

```bash
mkdir -p Sources/iTabPager/Internal
touch Sources/iTabPager/Internal/Lerp.swift
touch Sources/iTabPager/Internal/TabFrameKey.swift
touch Sources/iTabPager/TabPagerStyle.swift
touch Sources/iTabPager/PagerScrollView.swift
touch Sources/iTabPager/TabPager.swift
```

- [ ] **Step 3: 验证 Package 可编译**

```bash
swift build
```

Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Package.swift Sources/
git commit -m "chore: scaffold project structure with iOS 17 platform"
```

---

## Task 2: Lerp 工具函数（TDD）

**Files:**
- Create: `Sources/iTabPager/Internal/Lerp.swift`
- Modify: `Tests/iTabPagerTests/iTabPagerTests.swift`

- [ ] **Step 1: 写失败测试**

```swift
// Tests/iTabPagerTests/iTabPagerTests.swift
import XCTest
@testable import iTabPager

final class LerpTests: XCTestCase {
    func test_lerp_atZero() {
        XCTAssertEqual(lerp(0, 10, 0), 0)
    }
    func test_lerp_atOne() {
        XCTAssertEqual(lerp(0, 10, 1), 10)
    }
    func test_lerp_midpoint() {
        XCTAssertEqual(lerp(0, 10, 0.5), 5)
    }
    func test_lerp_arbitrary() {
        XCTAssertEqual(lerp(100, 200, 0.3), 130, accuracy: 0.001)
    }
    func test_lerp_reverseDirection() {
        XCTAssertEqual(lerp(10, 0, 0.3), 7, accuracy: 0.001)
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
swift test --filter LerpTests
```

Expected: 编译错误 `use of unresolved identifier 'lerp'`

- [ ] **Step 3: 实现 lerp**

```swift
// Sources/iTabPager/Internal/Lerp.swift
import CoreGraphics

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}
```

- [ ] **Step 4: 运行测试，确认全部通过**

```bash
swift test --filter LerpTests
```

Expected: `Test Suite 'LerpTests' passed`

- [ ] **Step 5: Commit**

```bash
git add Sources/iTabPager/Internal/Lerp.swift Tests/iTabPagerTests/iTabPagerTests.swift
git commit -m "feat: add lerp utility with tests"
```

---

## Task 3: TabPagerStyle

**Files:**
- Create: `Sources/iTabPager/TabPagerStyle.swift`

- [ ] **Step 1: 实现 TabPagerStyle**

```swift
// Sources/iTabPager/TabPagerStyle.swift
import SwiftUI

public struct TabPagerStyle {
    public var selectedFont: Font      = .system(size: 17, weight: .bold)
    public var unselectedFont: Font    = .system(size: 17, weight: .regular)
    public var selectedColor: Color    = .primary
    public var unselectedColor: Color  = .secondary
    public var indicatorColor: Color   = .primary
    public var indicatorWidthRatio: CGFloat = 0.5
    public var indicatorHeight: CGFloat = 3
    public var indicatorSpacing: CGFloat = 0
    public var tabSpacing: CGFloat     = 20

    public init() {}
}
```

- [ ] **Step 2: 编译验证**

```bash
swift build
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/iTabPager/TabPagerStyle.swift
git commit -m "feat: add TabPagerStyle"
```

---

## Task 4: TabFrameKey PreferenceKey

**Files:**
- Create: `Sources/iTabPager/Internal/TabFrameKey.swift`

- [ ] **Step 1: 实现 TabFrameKey**

```swift
// Sources/iTabPager/Internal/TabFrameKey.swift
import SwiftUI

struct TabFrameKey: PreferenceKey {
    static var defaultValue: [AnyHashable: CGRect] = [:]
    static func reduce(
        value: inout [AnyHashable: CGRect],
        nextValue: () -> [AnyHashable: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
swift build
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/iTabPager/Internal/TabFrameKey.swift
git commit -m "feat: add TabFrameKey preference key"
```

---

## Task 5: PagerScrollView（UIViewControllerRepresentable）

**Files:**
- Create: `Sources/iTabPager/PagerScrollView.swift`

这是核心 UIKit 桥接层，包含 `PagerScrollView`（representable 包装）和 `PagerViewController`（UIViewController 宿主，管理 UIScrollView 和 UIHostingController 懒加载）。UIKit 手势消歧和实时 offset 都在这里完成。

- [ ] **Step 1: 实现完整的 PagerScrollView.swift**

```swift
// Sources/iTabPager/PagerScrollView.swift
import SwiftUI
import UIKit

// MARK: - PagerScrollView

struct PagerScrollView<Tab: Hashable, Content: View>: UIViewControllerRepresentable {

    let tabs: [Tab]
    @Binding var selection: Tab
    @Binding var progress: CGFloat
    let content: (Tab) -> Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale

    func makeUIViewController(context: Context) -> PagerViewController<Tab, Content> {
        PagerViewController(
            tabs: tabs,
            selectionBinding: $selection,
            progressBinding: $progress,
            content: content
        )
    }

    func updateUIViewController(_ vc: PagerViewController<Tab, Content>, context: Context) {
        vc.update(
            tabs: tabs,
            selectionBinding: $selection,
            progressBinding: $progress,
            content: content,
            colorScheme: colorScheme,
            dynamicTypeSize: dynamicTypeSize,
            locale: locale
        )
    }
}

// MARK: - PagerViewController

final class PagerViewController<Tab: Hashable, Content: View>: UIViewController, UIScrollViewDelegate {

    // MARK: Properties

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bounces = true
        sv.clipsToBounds = true
        sv.backgroundColor = .clear
        return sv
    }()

    private var tabs: [Tab]
    private var selectionBinding: Binding<Tab>
    private var progressBinding: Binding<CGFloat>
    private var content: (Tab) -> Content
    private var colorScheme: ColorScheme = .light
    private var dynamicTypeSize: DynamicTypeSize = .large
    private var locale: Locale = .current

    private var hostingControllers: [Int: UIHostingController<AnyView>] = [:]
    private(set) var isUserScrolling = false

    // MARK: Init

    init(
        tabs: [Tab],
        selectionBinding: Binding<Tab>,
        progressBinding: Binding<CGFloat>,
        content: @escaping (Tab) -> Content
    ) {
        self.tabs = tabs
        self.selectionBinding = selectionBinding
        self.progressBinding = progressBinding
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        scrollView.delegate = self
        view.addSubview(scrollView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = view.bounds
        guard bounds.width > 0 else { return }
        scrollView.frame = bounds
        updateContentSize()
        updateAllPageFrames()
        // 旋转等布局变化后无动画跳到当前页
        if !isUserScrolling {
            let index = clampedIndex(for: selectionBinding.wrappedValue)
            scrollView.contentOffset = CGPoint(x: CGFloat(index) * bounds.width, y: 0)
        }
        updateVisiblePages()
    }

    // MARK: Public Update

    func update(
        tabs: [Tab],
        selectionBinding: Binding<Tab>,
        progressBinding: Binding<CGFloat>,
        content: @escaping (Tab) -> Content,
        colorScheme: ColorScheme,
        dynamicTypeSize: DynamicTypeSize,
        locale: Locale
    ) {
        self.tabs = tabs
        self.selectionBinding = selectionBinding
        self.progressBinding = progressBinding
        self.content = content
        self.colorScheme = colorScheme
        self.dynamicTypeSize = dynamicTypeSize
        self.locale = locale

        scrollView.isScrollEnabled = tabs.count > 1
        updateContentSize()
        updateAllPageFrames()

        // 外部 selection 变化（如 tab 点击）时程序化滚动
        if !isUserScrolling {
            let index = clampedIndex(for: selectionBinding.wrappedValue)
            let targetX = CGFloat(index) * scrollView.bounds.width
            if abs(scrollView.contentOffset.x - targetX) > 1 {
                scrollView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
            }
        }

        updateVisiblePages()
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        let rawProgress = scrollView.contentOffset.x / pageWidth
        let clampedProgress = max(0, min(rawProgress, CGFloat(tabs.count - 1)))
        progressBinding.wrappedValue = clampedProgress
        updateVisiblePages()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
        snapSelection()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isUserScrolling = false
    }

    // MARK: Private

    private func updateContentSize() {
        let pageWidth = scrollView.bounds.width
        scrollView.contentSize = CGSize(
            width: pageWidth * CGFloat(tabs.count),
            height: scrollView.bounds.height
        )
    }

    private func updateAllPageFrames() {
        let pageWidth = scrollView.bounds.width
        let pageHeight = scrollView.bounds.height
        for (index, vc) in hostingControllers {
            vc.view.frame = CGRect(
                x: CGFloat(index) * pageWidth,
                y: 0,
                width: pageWidth,
                height: pageHeight
            )
        }
    }

    private func updateVisiblePages() {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0, !tabs.isEmpty else { return }

        let currentIndex = Int(round(scrollView.contentOffset.x / pageWidth))
            .clamped(to: 0...(tabs.count - 1))
        let lo = max(0, currentIndex - 1)
        let hi = min(tabs.count - 1, currentIndex + 1)
        let pageHeight = scrollView.bounds.height

        // 卸载窗口外的页面
        for index in Array(hostingControllers.keys) where index < lo || index > hi {
            let vc = hostingControllers[index]!
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            hostingControllers.removeValue(forKey: index)
        }

        // 加载或更新窗口内的页面
        for index in lo...hi {
            let tab = tabs[index]
            let rootView = AnyView(
                content(tab)
                    .environment(\.colorScheme, colorScheme)
                    .environment(\.dynamicTypeSize, dynamicTypeSize)
                    .environment(\.locale, locale)
            )
            if let vc = hostingControllers[index] {
                vc.rootView = rootView
                vc.view.frame = CGRect(x: CGFloat(index) * pageWidth, y: 0, width: pageWidth, height: pageHeight)
            } else {
                let vc = UIHostingController(rootView: rootView)
                vc.view.backgroundColor = .clear
                addChild(vc)
                scrollView.addSubview(vc.view)
                vc.view.frame = CGRect(x: CGFloat(index) * pageWidth, y: 0, width: pageWidth, height: pageHeight)
                vc.didMove(toParent: self)
                hostingControllers[index] = vc
            }
        }
    }

    private func snapSelection() {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / pageWidth))
            .clamped(to: 0...(tabs.count - 1))
        selectionBinding.wrappedValue = tabs[index]
    }

    private func clampedIndex(for tab: Tab) -> Int {
        (tabs.firstIndex(of: tab) ?? 0).clamped(to: 0...(max(0, tabs.count - 1)))
    }
}

// MARK: - Comparable clamped helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

- [ ] **Step 2: 编译验证**

```bash
swift build
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/iTabPager/PagerScrollView.swift
git commit -m "feat: add PagerScrollView with UIScrollView paging and lazy loading"
```

---

## Task 6: TabPager（tab bar + body）

**Files:**
- Create: `Sources/iTabPager/TabPager.swift`

`TabPager` 是唯一的公开视图，由两部分组成：
1. `body`：VStack 组合 tabStripView + PagerScrollView，管理 `@State progress`
2. `tabStripView`（私有扩展）：横向可滚动 tab bar，读 `progress` 插值绘制指示器

- [ ] **Step 1: 实现 TabPager.swift**

```swift
// Sources/iTabPager/TabPager.swift
import SwiftUI

// MARK: - TabPager

public struct TabPager<Tab: Hashable, Content: View>: View {

    // MARK: Public Properties

    let tabs: [Tab]
    @Binding var selection: Tab
    var alignment: HorizontalAlignment
    var style: TabPagerStyle
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
        style: TabPagerStyle = .init(),
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

extension TabPager {

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
        let selected = selection == tab
        ZStack {
            // 占位用 selectedFont，保持 tab 宽度在选中/未选中时一致
            Text(tabTitle(tab))
                .font(style.selectedFont)
                .hidden()
            Text(tabTitle(tab))
                .font(selected ? style.selectedFont : style.unselectedFont)
                .foregroundStyle(selected ? style.selectedColor : style.unselectedColor)
                .animation(nil, value: selection)
        }
        .padding(.bottom, style.indicatorSpacing)
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
```

- [ ] **Step 2: 编译验证**

```bash
swift build
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/iTabPager/TabPager.swift
git commit -m "feat: add TabPager with tab strip and progress-driven indicator"
```

---

## Task 7: 单元测试——selection 修正逻辑（TDD）

**Files:**
- Modify: `Tests/iTabPagerTests/iTabPagerTests.swift`
- Modify: `Sources/iTabPager/TabPager.swift`

- [ ] **Step 1: 先写失败测试**

在 `iTabPagerTests.swift` 中追加（此时 `validatedSelection` 还不存在，编译会报错）：

```swift
final class SelectionValidationTests: XCTestCase {
    func test_validSelection_returnsItself() {
        let result = TabPager<Int, EmptyView>.validatedSelection(2, in: [1, 2, 3])
        XCTAssertEqual(result, 2)
    }

    func test_invalidSelection_returnsFirstTab() {
        let result = TabPager<Int, EmptyView>.validatedSelection(99, in: [1, 2, 3])
        XCTAssertEqual(result, 1)
    }

    func test_emptyTabs_returnsNil() {
        let result = TabPager<Int, EmptyView>.validatedSelection(1, in: [])
        XCTAssertNil(result)
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

```bash
swift test --filter SelectionValidationTests
```

Expected: 编译错误 `type 'TabPager<Int, EmptyView>' has no member 'validatedSelection'`

- [ ] **Step 3: 在 TabPager.swift 末尾添加 internal 工具函数**

```swift
// MARK: - Internal Helpers (testable)

extension TabPager {
    static func validatedSelection(_ selection: Tab, in tabs: [Tab]) -> Tab? {
        tabs.contains(selection) ? selection : tabs.first
    }
}
```

- [ ] **Step 4: 运行测试，确认全部通过**

```bash
swift test --filter SelectionValidationTests
```

Expected: `Test Suite 'SelectionValidationTests' passed`

- [ ] **Step 5: 运行全部测试**

```bash
swift test
```

Expected: 全部 pass（LerpTests + SelectionValidationTests）

- [ ] **Step 6: Commit**

```bash
git add Sources/iTabPager/TabPager.swift Tests/iTabPagerTests/iTabPagerTests.swift
git commit -m "feat: add selection validation with tests"
```

---

## Task 8: 最终验证 & 清理

**Files:**
- Modify: `Sources/iTabPager/iTabPager.swift`（删除模板注释，添加公开 re-export 注释）

- [ ] **Step 1: 清理模板文件**

`Sources/iTabPager/iTabPager.swift` 默认只有一行注释，可以直接留空或删除（Package 不需要它）：

```bash
rm Sources/iTabPager/iTabPager.swift
```

- [ ] **Step 2: 运行全量编译 + 测试**

```bash
swift build && swift test
```

Expected: `Build complete!` + 全部测试 pass

- [ ] **Step 3: 检查公开 API surface**

```bash
swift package dump-package
```

确认 `iTabPager` 产品只暴露 `TabPager` 和 `TabPagerStyle` 两个公开类型。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove template file, finalize build"
```

---

## 手动测试清单（在宿主 App 中验证，非 Package 内）

实现完成后，在任意 iOS 17 App 里集成此 Package，验证以下场景：

| 场景 | 预期行为 |
|---|---|
| 点击 tab | 内容容器切页，tab bar 指示器跳至对应 tab |
| 左右滑动内容 | 指示器跟随手指在两个 tab 之间线性插值 |
| 上下滑动内容（List） | 横向 pager 不触发，内容正常竖向滚动 |
| 对角线快速划 | 系统自动消歧，取初始主方向 |
| 5+ 个 tab 溢出 tab bar | tab bar 可横向滚动，点击 tab 后自动居中 |
| 只有 1 个 tab | 内容无法横向滑动，指示器静止 |
| 设备旋转 | 页面自动重新布局，停留在当前 tab |
