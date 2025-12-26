//
//  ScrollViewWraper.swift
//  QuickLayoutDemo
//
//  Created by Sondra on 2025/12/24.
//

import UIKit
import QuickLayout

// MARK: - ScrollView Container View
/// A scroll view encapsulation with a style similar to SwiftUI ScrollView
/// Reference: https://facebookincubator.github.io/QuickLayout/how-to-use/macro-layout-integration-donts/

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

    init(
        _ scrollView: QLScrollView,
        axis: Axis,
        children: [Element],
    ) {
        self.scrollView = scrollView
        scrollView.axis = axis
        scrollView.children = children
        
    }
    
    func quick_layoutThatFits(_ proposedSize: CGSize) -> LayoutNode {
        
        return scrollView.quick_layoutThatFits(proposedSize)
    }
    
    func quick_flexibility(for axis: Axis) -> Flexibility {
        return scrollView.quick_flexibility(for: axis)
    }
    
    func quick_layoutPriority() -> CGFloat {
        return scrollView.quick_layoutPriority()
    }
    
    func quick_extractViewsIntoArray(_ views: inout [UIView]) {
        views.append(scrollView)
    }
    
    func backingView() -> UIView? {
        scrollView
    }
    
}
