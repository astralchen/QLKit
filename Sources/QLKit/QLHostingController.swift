import UIKit
import QuickLayout

/// A UIViewController that hosts QuickLayout content, similar to SwiftUI's UIHostingController
///
/// Usage:
/// ```swift
/// class MyViewController: QLHostingController {
///     override var body: Layout {
///         VStack {
///             titleLabel
///             subtitleLabel
///         }
///     }
/// }
/// ```
open class QLHostingController: UIViewController {
    
    // MARK: - Properties

    /// The container view that will hold our layout
    @QuickLayout
    final class ContainerView: UIView {
        weak var hostingController: QLHostingController?

        var body: Layout {
            hostingController?.body ?? EmptyLayout()
        }
    }

    private lazy var containerView: ContainerView = {
        let view = ContainerView()
        view.hostingController = self
        return view
    }()

    // MARK: - Layout Body

    /// Override this property to provide your layout
    /// This is similar to SwiftUI's body property
    @LayoutBuilder
    open var body: Layout {
        EmptyLayout()
    }

    // MARK: - Lifecycle

    override open func loadView() {
        view = containerView
        view.backgroundColor = .systemBackground
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Layout Updates

    /// Call this method to trigger a layout rebuild when your state changes
    open func setNeedsLayoutUpdate() {
        containerView.setNeedsLayout()
    }

    /// Forces an immediate layout update
    open func layoutIfNeeded() {
        containerView.layoutIfNeeded()
    }

    open func sizeThatFits(in size: CGSize) -> CGSize {
        return containerView.sizeThatFits(size)
    }
}
