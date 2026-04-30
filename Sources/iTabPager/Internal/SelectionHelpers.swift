// Pure Swift — no UIKit dependency, testable on macOS host
func validatedSelection<Tab: Hashable>(_ selection: Tab, in tabs: [Tab]) -> Tab? {
    tabs.contains(selection) ? selection : tabs.first
}
