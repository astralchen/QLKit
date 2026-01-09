//
//  ScrollElement.swift
//  QLKit
//
//  Created by Sondra on 2025/12/24.
//

import UIKit
import QuickLayout

// MARK: - ScrollView Container

/// Creates a SwiftUI-like `ScrollView` wrapper for `QLScrollView`.
///
/// This API lets you declare scrollable content using QuickLayout `Element`s, while `QLScrollView`
/// handles sizing and `contentSize` updates internally.
///
/// Reference: https://facebookincubator.github.io/QuickLayout/how-to-use/macro-layout-integration-donts/
///
/// - Parameters:
///   - scrollView: The `QLScrollView` instance used as the backing view.
///   - axis: The scroll axis. Defaults to `.vertical`.
///   - children: A builder closure that produces the scroll content elements.
/// - Returns: A `Layout` + `LeafElement` that renders using the provided `QLScrollView`.
///
@MainActor public func ScrollView(
    _ scrollView: QLScrollView,
    axis: QuickLayout.Axis = .vertical,
    @FastArrayBuilder<Element> children: () -> [Element]
) -> LeafElement & Layout   {
    ScrollElement(scrollView, axis: axis, children: children())
}



@MainActor
private struct ScrollElement: @MainActor Layout, @MainActor LeafElement {

    private let scrollView: QLScrollView

    /// Creates a leaf layout element backed by a configured `QLScrollView`.
    ///
    /// This initializer configures `scrollView.axis` and `scrollView.children` immediately.
    init(
        _ scrollView: QLScrollView,
        axis: Axis,
        children: [Element],
    ) {
        self.scrollView = scrollView
        scrollView.axis = axis
        scrollView.children = children

    }

    /// Delegates layout computation to the backing `QLScrollView`.
    func quick_layoutThatFits(_ proposedSize: CGSize) -> LayoutNode {
        scrollView.quick_layoutThatFits(proposedSize)
    }

    /// Delegates flexibility reporting to the backing `QLScrollView`.
    func quick_flexibility(for axis: Axis) -> Flexibility {
        scrollView.quick_flexibility(for: axis)
    }
    
    /// Delegates layout priority reporting to the backing `QLScrollView`.
    func quick_layoutPriority() -> CGFloat {
        scrollView.quick_layoutPriority()
    }

    /// Extracts the backing view into the view array used by QuickLayout.
    func quick_extractViewsIntoArray(_ views: inout [UIView]) {
        views.append(scrollView)
    }

    /// Returns the concrete backing `UIView` for this leaf element.
    func backingView() -> UIView? {
        scrollView
    }

}
