#if canImport(UIKit)
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
    private var isResizing = false
    private var pendingTargetIndex: Int? = nil

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
        if !isUserScrolling {
            let index = clampedIndex(for: selectionBinding.wrappedValue)
            isResizing = true
            scrollView.contentOffset = CGPoint(x: CGFloat(index) * bounds.width, y: 0)
            isResizing = false
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

        let targetIndex = clampedIndex(for: selectionBinding.wrappedValue)
        let targetX = CGFloat(targetIndex) * scrollView.bounds.width

        if !isUserScrolling {
            if abs(scrollView.contentOffset.x - targetX) > 1 && pendingTargetIndex != targetIndex {
                pendingTargetIndex = targetIndex
                scrollView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
            }
        }

        // 用实际 offset 是否到达目标来判断是否在滚动——不依赖标志位，
        // 对动画被打断导致 pendingTargetIndex 提前清除的情况免疫。
        let notAtTarget = abs(scrollView.contentOffset.x - targetX) > 1
        if !isUserScrolling && !scrollView.isDecelerating && !notAtTarget {
            updateVisiblePages()
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
        pendingTargetIndex = nil
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isUserScrolling = false
            snapSelection()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isResizing else { return }
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        let rawProgress = scrollView.contentOffset.x / pageWidth
        let clampedProgress = max(0, min(rawProgress, CGFloat(tabs.count - 1)))
        progressBinding.wrappedValue = clampedProgress
        loadUnloadPages()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
        snapSelection()
        updateVisiblePages()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isUserScrolling = false
        // 只有真正到达当前目标才清除：UIKit 在打断动画时也会触发此回调，
        // 若此时 offset 尚未到位，说明新动画仍在运行，不能清除 pendingTargetIndex。
        let currentIndex = clampedIndex(for: selectionBinding.wrappedValue)
        let targetX = CGFloat(currentIndex) * scrollView.bounds.width
        if abs(scrollView.contentOffset.x - targetX) <= 1 {
            pendingTargetIndex = nil
        }
        updateVisiblePages()
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

    private func loadUnloadPages() {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0, !tabs.isEmpty else { return }
        let currentIndex = Int(round(scrollView.contentOffset.x / pageWidth))
            .clamped(to: 0...(tabs.count - 1))
        let lo = max(0, currentIndex - 1)
        let hi = min(tabs.count - 1, currentIndex + 1)
        let pageHeight = scrollView.bounds.height

        // Unload out-of-window pages
        for index in Array(hostingControllers.keys) where index < lo || index > hi {
            let vc = hostingControllers[index]!
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            hostingControllers.removeValue(forKey: index)
        }

        // Load new pages (with current environment — they'll be refreshed in update())
        for index in lo...hi where hostingControllers[index] == nil {
            let tab = tabs[index]
            let rootView = AnyView(
                content(tab)
                    .environment(\.colorScheme, colorScheme)
                    .environment(\.dynamicTypeSize, dynamicTypeSize)
                    .environment(\.locale, locale)
            )
            let vc = UIHostingController(rootView: rootView)
            vc.view.backgroundColor = .clear
            addChild(vc)
            scrollView.addSubview(vc.view)
            vc.view.frame = CGRect(x: CGFloat(index) * pageWidth, y: 0, width: pageWidth, height: pageHeight)
            vc.didMove(toParent: self)
            hostingControllers[index] = vc
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

        // Unload out-of-window pages
        for index in Array(hostingControllers.keys) where index < lo || index > hi {
            let vc = hostingControllers[index]!
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            hostingControllers.removeValue(forKey: index)
        }

        // Load or update pages in window
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
#endif
