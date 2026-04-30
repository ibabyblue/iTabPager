import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
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
