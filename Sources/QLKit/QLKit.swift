// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit
import QuickLayout

extension UIView {

    /// Converts the view’s `safeAreaInsets` to `QuickLayout.EdgeInsets`.
    ///
    /// - Important:
    ///   Respects the view’s `effectiveUserInterfaceLayoutDirection`.
    ///
    /// - Note:
    ///   Access this value after layout (e.g. `viewDidLayoutSubviews`).
    public var safeAreaEdgeInsets: QuickLayout.EdgeInsets {
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft

        return .init(
            top: safeAreaInsets.top,
            leading: isRTL ? safeAreaInsets.right : safeAreaInsets.left,
            bottom: safeAreaInsets.bottom,
            trailing: isRTL ? safeAreaInsets.left : safeAreaInsets.right
        )
    }
}

/// Maps a list of `UIView` instances into a QuickLayout `FastExpression`.
///
/// This helper mirrors the common `ForEach` pattern by transforming each item into an `Element`
/// and grouping the results into a single expression that can be used inside layout builders
/// like `VStack`/`HStack`.
///
/// - Parameters:
///   - list: The source views to iterate over.
///   - map: A closure that converts each view into an `Element` (optionally applying modifiers).
/// - Returns: A `FastExpression` that contains the mapped elements in order.
public func ForEach<T>(_ list: [T], map: (T) -> Element) -> FastExpression where T: UIView {
    BlockExpression(expressions: list.map { ValueExpression<Element>(value: map($0)) })
}
