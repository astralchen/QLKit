import UIKit
import QuickLayout

/// A view controller that hosts QuickLayout content.
///
/// Subclass `QuickLayoutHostingController` and override ``body`` to provide the
/// QuickLayout hierarchy for the controller's root view, or create an instance
/// with ``init(content:)`` to provide content inline.
open class QuickLayoutHostingController: UIViewController {

    // MARK: - Properties

    /// The root view that evaluates the hosted layout.
    @QuickLayout
    final class ContainerView: UIView {
        weak var hostingController: QuickLayoutHostingController?

        var body: Layout {
            hostingController?.body ?? EmptyLayout()
        }
    }

    private var contentProvider: (() -> Layout)?

    private lazy var containerView: ContainerView = {
        let view = ContainerView()
        view.hostingController = self
        return view
    }()

    // MARK: - Initialization

    /// Creates a hosting controller with inline QuickLayout content.
    ///
    /// - Parameter content: A closure that returns the hosted content.
    public convenience init(@LayoutBuilder content: @escaping () -> Layout) {
        self.init(nibName: nil, bundle: nil)
        self.contentProvider = content
    }

    // MARK: - Layout Body

    /// The QuickLayout content hosted by the view controller.
    ///
    /// The default implementation returns an empty layout. Subclasses override
    /// this property to return their root layout.
    @LayoutBuilder
    open var body: Layout {
        if let contentProvider {
            contentProvider()
        } else {
            EmptyLayout()
        }
    }

    // MARK: - Lifecycle

    override open func loadView() {
        view = containerView
        view.backgroundColor = .systemBackground
    }

    // MARK: - Layout Updates

    /// Invalidates the hosted layout.
    ///
    /// Call this method after changing state that affects ``body``.
    open func setNeedsLayoutUpdate() {
        containerView.setNeedsLayout()
    }

    /// Lays out the hosted content immediately if needed.
    open func layoutIfNeeded() {
        containerView.layoutIfNeeded()
    }

    /// Returns the size that best fits the specified constraints.
    ///
    /// - Parameter size: The maximum size available to the hosted content.
    /// - Returns: The size that fits the hosted layout.
    open func sizeThatFits(in size: CGSize) -> CGSize {
        return containerView.sizeThatFits(size)
    }
}
