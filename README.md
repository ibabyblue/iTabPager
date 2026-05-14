# ITabPager

A tab-strip pager component for iOS 17+. UIScrollView paging core, SwiftUI public API, zero third-party dependencies.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 6.2](https://img.shields.io/badge/Swift-6.2%2B-orange)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

- **Real-time indicator** — interpolates position and width between tab frames driven by `scrollViewDidScroll`, no delay, fully finger-tracking
- **Overflow tab strip** — horizontally scrollable tab bar; tapping a tab auto-centers it within the strip
- **Lazy page loading** — only the current page and its immediate neighbors are kept in memory
- **Customizable style** — fonts, colors, indicator size, spacing all configurable via `ITabPagerStyle`
- **SwiftUI-native public API** — zero UIKit exposure to callers, zero third-party dependencies

## Requirements

| | Minimum |
|---|---|
| iOS | 17.0 |
| Swift | 6.2 |
| Xcode | 16.3 |

## Installation

### Swift Package Manager

In Xcode choose **File → Add Package Dependencies**, enter the repository URL, or add to `Package.swift` directly:

```swift
dependencies: [
    .package(url: "https://github.com/ibabyblue/ITabPager", from: "0.0.2")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ITabPager", package: "ITabPager")
        ]
    )
]
```

## Quick Start

```swift
import ITabPager

enum Tab: String, CaseIterable {
    case recommended = "推荐"
    case hot         = "热门"
    case latest      = "最新"
}

struct ContentView: View {
    @State private var selection: Tab = .recommended

    var body: some View {
        ITabPager(
            tabs: Tab.allCases,
            selection: $selection,
            content: { tab in
                List(0..<30, id: \.self) { i in
                    Text("\(tab.rawValue) · \(i + 1)")
                }
                .listStyle(.plain)
            },
            tabTitle: { $0.rawValue }
        )
    }
}
```

## Custom Style

```swift
var style: ITabPagerStyle {
    var s = ITabPagerStyle()
    s.selectedColor       = .orange
    s.indicatorColor      = .orange
    s.indicatorWidthRatio = 0.6
    s.indicatorHeight     = 2
    s.indicatorSpacing    = 4
    s.tabSpacing          = 24
    return s
}

ITabPager(
    tabs: tabs,
    selection: $selection,
    alignment: .center,
    style: style,
    content: { tab in MyPageView(tab: tab) },
    tabTitle: { tab in tab.title }
)
```

## API Reference

### ITabPager

```swift
public struct ITabPager<Tab: Hashable, Content: View>: View {
    public init(
        tabs: [Tab],
        selection: Binding<Tab>,
        alignment: HorizontalAlignment = .leading,
        style: ITabPagerStyle = .init(),
        @ViewBuilder content: @escaping (Tab) -> Content,
        tabTitle: @escaping (Tab) -> String
    )
}
```

### ITabPagerStyle

```swift
public struct ITabPagerStyle {
    public var selectedFont: Font         // default: .system(size: 17, weight: .bold)
    public var unselectedFont: Font       // default: .system(size: 17, weight: .regular)
    public var selectedColor: Color       // default: .primary
    public var unselectedColor: Color     // default: .secondary
    public var indicatorColor: Color      // default: .primary
    public var indicatorWidthRatio: CGFloat  // default: 0.5
    public var indicatorHeight: CGFloat   // default: 3
    public var indicatorSpacing: CGFloat  // default: 0
    public var tabSpacing: CGFloat        // default: 20
}
```

| Property | Description |
|---|---|
| `selectedFont` / `unselectedFont` | Tab label fonts |
| `selectedColor` / `unselectedColor` | Tab label colors |
| `indicatorColor` | Indicator bar color |
| `indicatorWidthRatio` | Indicator width as a fraction of the tab label width |
| `indicatorHeight` | Indicator bar height in points |
| `indicatorSpacing` | Gap between the tab label bottom and the indicator bar |
| `tabSpacing` | Horizontal spacing between tab labels |

## Edge-Case Behavior

| Scenario | Behavior |
|---|---|
| `tabs` is empty | Renders nothing, no crash |
| `tabs.count == 1` | Paging disabled, single page shown |
| `selection` not in `tabs` | Corrected to `tabs.first` automatically |
| `tabs` replaced at runtime | Pages reload; selection snaps to nearest valid tab |
| Rapid tab taps | Each tap interrupts the previous animation and starts a new one immediately |

## Demo

Open `demo/ITabPagerDemo.xcodeproj`, select a simulator and run. Covers three scenarios:

- **Basic** — three-tab pager with a plain list
- **Overflow** — fifteen tabs that overflow the strip; auto-scrolls to keep the selected tab visible
- **Custom Style** — custom fonts, colors, and indicator appearance; center-aligned tabs

## Design Notes

- Core: `UIScrollView` with `isPagingEnabled = true` wrapped in `UIViewControllerRepresentable`. Each page is a `UIHostingController`; only the current page and its immediate neighbors are kept in memory.
- Tab colors and fonts cross-fade continuously with scroll progress — the selected layer fades in as the adjacent page scrolls into view, matching the indicator in real time.
- The indicator interpolates position and width between neighboring tab frames, driven by `scrollViewDidScroll`, producing smooth finger-tracking animation.
- Programmatic tab switches use `setContentOffset(animated:)`. A `pendingTargetIndex` guard prevents redundant animation restarts from the SwiftUI re-render loop; the guard is cleared only when the scroll view physically reaches the target offset.
- The public API is entirely SwiftUI; callers have no exposure to UIKit.

## Out of Scope

- Vertical tab strips
- Drag-to-reorder tabs
- macOS / tvOS / watchOS

## License

ITabPager is available under the MIT license. See the [LICENSE](LICENSE) file for details.
