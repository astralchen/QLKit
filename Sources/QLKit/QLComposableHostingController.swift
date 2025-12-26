//
//  QLComposableHostingController.swift
//  QLKit
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout

// MARK: - Alternative Approach: Composition-based Hosting Controller

/// A composition-based hosting controller that takes a layout in the initializer
/// Use this when you want to create layouts inline without subclassing
public final class QLComposableHostingController: UIViewController {

    @QuickLayout
    final class ContainerView: UIView {
        var layoutProvider: () -> Layout

        init(layoutProvider: @escaping () -> Layout) {
            self.layoutProvider = layoutProvider
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        var body: Layout {
            layoutProvider()
        }
    }

    private let layoutProvider: () -> Layout
    private lazy var containerView: ContainerView = {
        ContainerView(layoutProvider: layoutProvider)
    }()

    // MARK: - Initialization

    /// Initialize with a layout builder closure
    /// - Parameter builder: Closure that returns the layout
    public init(@LayoutBuilder builder: @escaping () -> Layout) {
        self.layoutProvider = builder
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func loadView() {
        view = containerView
        view.backgroundColor = .systemBackground
    }

    // MARK: - Layout Management

    /// Rebuilds the layout
    public func setNeedsLayoutUpdate() {
        containerView.setNeedsLayout()
    }

    /// Forces an immediate layout update
    public func layoutIfNeeded() {
        containerView.layoutIfNeeded()
    }
}

// MARK: - Convenience Extensions for Composable Controller

extension QLComposableHostingController {

    /// Creates a navigation controller with this hosting controller as root
    public func wrappedInNavigationController() -> UINavigationController {
        return UINavigationController(rootViewController: self)
    }

    /// Sets the title
    @discardableResult
    public func withTitle(_ title: String?) -> Self {
        self.title = title
        return self
    }

    /// Sets the background color
    @discardableResult
    public func withBackgroundColor(_ color: UIColor) -> Self {
        view.backgroundColor = color
        return self
    }
}
