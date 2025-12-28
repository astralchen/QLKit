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

public func ForEach<T>(_ list: [T], map: (T) -> Element) -> FastExpression where  T: UIView {
  BlockExpression(expressions: list.map { ValueExpression<Element>(value: map($0)) })
}
