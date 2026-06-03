import UIKit

/// A UIKit view that embeds a child view controller inside a QuickLayout body.
///
/// `QuickLayoutViewControllerRepresentable` mirrors SwiftUI's representable
/// naming style while staying UIKit-first: callers provide an already-created
/// child view controller. The representable resolves its parent view controller
/// from the UIKit responder chain when it enters a view hierarchy. For lazy
/// creation, wrap this view in QuickLayout's `LazyView`.
@MainActor
public final class QuickLayoutViewControllerRepresentable: UIView, QuickLayoutUpdating {

    /// Containment and layout events emitted by the representable.
    public enum Event: Equatable {
        /// The representable moved to or from a superview.
        case didMoveToSuperview
        /// The parent view controller reference was captured or replaced.
        case didCaptureParent
        /// The child view controller is about to be attached to its parent.
        case willAttach
        /// The child view controller was attached to its parent.
        case didAttach
        /// The child view controller is about to be detached from its parent.
        case willDetach
        /// The child view controller was detached from its parent.
        case didDetach
        /// The hosted view controller is about to be replaced.
        case willReplaceViewController
        /// The hosted view controller was replaced.
        case didReplaceViewController
        /// The hosted view controller is about to be dismantled.
        case willDismantleViewController
        /// The hosted view controller was dismantled.
        case didDismantleViewController
        /// The representable needs a parent before it can attach the child.
        case missingParent
        /// The child already belongs to a different parent.
        case viewControllerAlreadyParented
        /// The child view was laid out inside the representable.
        case didLayoutSubviews
        /// The hosted child layout was invalidated.
        case didInvalidateChildLayout

        /// A stable string name for logging and tests.
        public var name: String {
            switch self {
            case .didMoveToSuperview:
                return "didMoveToSuperview"
            case .didCaptureParent:
                return "didCaptureParent"
            case .willAttach:
                return "willAttach"
            case .didAttach:
                return "didAttach"
            case .willDetach:
                return "willDetach"
            case .didDetach:
                return "didDetach"
            case .willReplaceViewController:
                return "willReplaceViewController"
            case .didReplaceViewController:
                return "didReplaceViewController"
            case .willDismantleViewController:
                return "willDismantleViewController"
            case .didDismantleViewController:
                return "didDismantleViewController"
            case .missingParent:
                return "missingParent"
            case .viewControllerAlreadyParented:
                return "viewControllerAlreadyParented"
            case .didLayoutSubviews:
                return "didLayoutSubviews"
            case .didInvalidateChildLayout:
                return "didInvalidateChildLayout"
            }
        }
    }

    /// A stable detailed-event kind.
    public typealias EventKind = Event

    /// A containment or layout event with contextual controller references.
    public struct DetailedEvent {

        /// The event kind.
        public let kind: EventKind

        /// The parent view controller involved in the event.
        public let parent: UIViewController?

        /// The primary child view controller involved in the event.
        public let viewController: UIViewController?

        /// The previous child when replacing hosted controllers.
        public let oldViewController: UIViewController?

        /// The new child when replacing hosted controllers.
        public let newViewController: UIViewController?

        /// Optional diagnostic context.
        public let reason: String?
    }

    /// The currently hosted child view controller.
    public private(set) var viewController: UIViewController?

    /// Receives containment and layout events.
    public var eventHandler: ((Event) -> Void)?

    /// Receives containment and layout events with parent and child context.
    public var detailedEventHandler: ((DetailedEvent) -> Void)?

    /// Enables lightweight preferred-content-size change detection during
    /// measurement.
    public var observesPreferredContentSizeChanges = true

    private weak var parentViewController: UIViewController?
    private var isAttached = false
    private var usesExplicitParent = false
    private var lastPreferredContentSize: CGSize = .zero

    /// Creates a representable view for a child view controller.
    ///
    /// The parent view controller is resolved automatically from the UIKit
    /// responder chain when the representable enters a controller-owned view
    /// hierarchy.
    ///
    /// - Parameter viewController: The child view controller to embed.
    public init(_ viewController: UIViewController) {
        self.viewController = viewController
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = false
    }

    /// Creates a representable view for a child view controller with an explicit parent.
    ///
    /// - Parameters:
    ///   - viewController: The child view controller to embed.
    ///   - parent: The parent view controller that owns containment.
    public init(_ viewController: UIViewController, parent: UIViewController) {
        self.viewController = viewController
        self.parentViewController = parent
        self.usesExplicitParent = true
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = false
    }

    /// Creates a representable view from Interface Builder.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        clipsToBounds = false
    }

    /// Replaces the hosted child view controller.
    ///
    /// If the representable is currently in a QuickLayout hierarchy, the old
    /// child is detached before the new child is attached.
    public func setViewController(_ viewController: UIViewController?) {
        guard self.viewController !== viewController else {
            attachIfNeeded()
            return
        }

        let oldViewController = self.viewController
        emit(
            .willReplaceViewController,
            viewController: oldViewController,
            oldViewController: oldViewController,
            newViewController: viewController
        )
        detachIfNeeded()
        removeCurrentChildViewIfNeeded()
        self.viewController = viewController
        lastPreferredContentSize = viewController?.preferredContentSize ?? .zero
        attachIfNeeded()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        emit(
            .didReplaceViewController,
            viewController: viewController,
            oldViewController: oldViewController,
            newViewController: viewController
        )
    }

    /// Detaches and releases the hosted child view controller.
    public func dismantleViewController() {
        emit(.willDismantleViewController)
        detachIfNeeded()
        removeCurrentChildViewIfNeeded()
        viewController = nil
        lastPreferredContentSize = .zero
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        emit(.didDismantleViewController)
    }

    /// Captures or replaces the parent view controller used for containment.
    ///
    /// If the representable is already attached to a different parent, the old
    /// containment relationship is removed and the child is attached to the new
    /// parent when the representable is visible.
    public func captureParent(_ parent: UIViewController) {
        guard parentViewController !== parent else {
            usesExplicitParent = true
            emit(.didCaptureParent)
            attachIfNeeded()
            return
        }

        detachIfNeeded()
        parentViewController = parent
        usesExplicitParent = true
        emit(.didCaptureParent)
        attachIfNeeded()
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        emit(.didMoveToSuperview)

        if superview == nil {
            detachIfNeeded()
        } else {
            attachIfNeeded()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        attachIfNeeded()
        if let childView = viewController?.view {
            childView.frame = bounds
        }
        emit(.didLayoutSubviews)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let viewController else {
            return .zero
        }

        let preferredSize = viewController.preferredContentSize
        updatePreferredContentSizeIfNeeded(preferredSize)
        if preferredSize != .zero {
            return clamped(preferredSize, to: size)
        }

        let targetSize = CGSize(
            width: size.width.isFinite ? size.width : UIView.layoutFittingCompressedSize.width,
            height: size.height.isFinite ? size.height : UIView.layoutFittingCompressedSize.height
        )
        let horizontalPriority: UILayoutPriority = size.width.isFinite ? .required : .fittingSizeLevel
        let verticalPriority: UILayoutPriority = size.height.isFinite ? .required : .fittingSizeLevel
        viewController.loadViewIfNeeded()
        guard let childView = viewController.view else {
            return .zero
        }

        let measuredSize = childView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalPriority,
            verticalFittingPriority: verticalPriority
        )

        return clamped(measuredSize, to: size)
    }

    /// Invalidates the hosted controller layout.
    public func setNeedsQuickLayout() {
        setNeedsLayout()
        viewController?.view?.setNeedsLayout()
    }

    /// Lays out the hosted controller view immediately if needed.
    public func quickLayoutIfNeeded() {
        layoutIfNeeded()
        viewController?.view?.layoutIfNeeded()
    }

    /// Invalidates the hosted child controller layout and representable size.
    public func invalidateChildLayout() {
        viewController?.view?.setNeedsLayout()
        viewController?.view?.invalidateIntrinsicContentSize()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        superview?.setNeedsLayout()
        emit(.didInvalidateChildLayout)
    }
}

private extension QuickLayoutViewControllerRepresentable {

    func attachIfNeeded() {
        guard superview != nil else {
            return
        }
        guard let viewController else {
            return
        }
        resolveParentIfNeeded()
        guard !isAttached else {
            return
        }
        guard let parentViewController else {
            emit(.missingParent, viewController: viewController, reason: "No parent view controller in responder chain.")
            return
        }
        if let existingParent = viewController.parent, existingParent !== parentViewController {
            emit(
                .viewControllerAlreadyParented,
                parent: existingParent,
                viewController: viewController,
                reason: "The child already belongs to another parent."
            )
            return
        }

        emit(.willAttach, parent: parentViewController, viewController: viewController)

        if viewController.parent == nil {
            parentViewController.addChild(viewController)
        }

        viewController.loadViewIfNeeded()
        guard let childView = viewController.view else {
            return
        }

        if childView.superview !== self {
            childView.removeFromSuperview()
            childView.frame = bounds
            childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(childView)
        }

        viewController.didMove(toParent: parentViewController)
        isAttached = true
        setNeedsLayout()

        lastPreferredContentSize = viewController.preferredContentSize
        emit(.didAttach, parent: parentViewController, viewController: viewController)
    }

    func resolveParentIfNeeded() {
        guard !usesExplicitParent, let resolvedParent = nearestOwningViewController() else {
            return
        }
        guard parentViewController !== resolvedParent else {
            return
        }

        detachIfNeeded()
        parentViewController = resolvedParent
        emit(.didCaptureParent, parent: resolvedParent, viewController: viewController)
    }

    func nearestOwningViewController() -> UIViewController? {
        var responder = next
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }

    func detachIfNeeded() {
        guard isAttached, let viewController else {
            return
        }

        let parentViewController = viewController.parent ?? parentViewController
        emit(.willDetach, parent: parentViewController, viewController: viewController)

        viewController.willMove(toParent: nil)
        viewController.view?.removeFromSuperview()
        viewController.removeFromParent()
        isAttached = false

        emit(.didDetach, parent: parentViewController, viewController: viewController)
    }

    func removeCurrentChildViewIfNeeded() {
        viewController?.view?.removeFromSuperview()
    }

    func emit(
        _ event: Event,
        parent: UIViewController? = nil,
        viewController: UIViewController? = nil,
        oldViewController: UIViewController? = nil,
        newViewController: UIViewController? = nil,
        reason: String? = nil
    ) {
        eventHandler?(event)
        detailedEventHandler?(
            DetailedEvent(
                kind: event,
                parent: parent ?? parentViewController,
                viewController: viewController ?? self.viewController,
                oldViewController: oldViewController,
                newViewController: newViewController,
                reason: reason
            )
        )
    }

    func clamped(_ measuredSize: CGSize, to maximumSize: CGSize) -> CGSize {
        CGSize(
            width: maximumSize.width.isFinite ? min(measuredSize.width, maximumSize.width) : measuredSize.width,
            height: maximumSize.height.isFinite ? min(measuredSize.height, maximumSize.height) : measuredSize.height
        )
    }

    func updatePreferredContentSizeIfNeeded(_ preferredContentSize: CGSize) {
        guard observesPreferredContentSizeChanges,
              preferredContentSize != lastPreferredContentSize else {
            return
        }

        lastPreferredContentSize = preferredContentSize
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}
