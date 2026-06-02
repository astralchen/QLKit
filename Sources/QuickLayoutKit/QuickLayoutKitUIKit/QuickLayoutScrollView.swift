//
//  QuickLayoutScrollView.swift
//  QuickLayoutKit
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuartzCore
import QuickLayout

/// Edges that a `QuickLayoutScrollView` can scroll to.
public enum QuickLayoutScrollEdge: Sendable {
    /// The top edge for vertical content.
    case top

    /// The bottom edge for vertical content.
    case bottom

    /// The leading edge for horizontal content.
    case leading

    /// The trailing edge for horizontal content.
    case trailing
}

/// Options used when replacing or appending scroll content.
public struct QuickLayoutScrollContentUpdateOptions: OptionSet, Sendable {
    public let rawValue: Int

    /// Creates an options value.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Preserves the current visible position by applying the measured content
    /// size delta after the update.
    public static let preserveVisiblePosition = QuickLayoutScrollContentUpdateOptions(rawValue: 1 << 0)

    /// Lays out the scroll view immediately after content changes.
    public static let layoutImmediately = QuickLayoutScrollContentUpdateOptions(rawValue: 1 << 1)
}

/// A scroll view that lays out QuickLayout elements as its content.
///
/// `QuickLayoutScrollView` measures its `contentElements` with QuickLayout and
/// updates its `contentSize` during layout.
open class QuickLayoutScrollView: UIScrollView, HasBody {

    // MARK: - Public Properties

    /// The axis along which the receiver scrolls.
    open var axis: QuickLayout.Axis = .vertical {
        didSet {
            if axis != oldValue {
                configureScrollBehavior()
                setNeedsLayout()
            }
        }
    }

    /// The elements laid out inside the scroll view.
    open var contentElements: [Element] = [] {
        didSet {
            setNeedsLayout()
        }
    }

    /// The alignment used when applying the measured content frame.
    open var contentAlignment: Alignment = .topLeading {
        didSet {
            setNeedsLayout()
        }
    }

    private var pendingScrollRequest: PendingScrollRequest?

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureScrollBehavior()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        configureScrollBehavior()
    }

    // MARK: - Configuration

    private func configureScrollBehavior() {
        switch axis {
        case .vertical:
            alwaysBounceVertical = true
            alwaysBounceHorizontal = false
            showsHorizontalScrollIndicator = false
            showsVerticalScrollIndicator = true
        case .horizontal:
            alwaysBounceVertical = false
            alwaysBounceHorizontal = true
            showsHorizontalScrollIndicator = true
            showsVerticalScrollIndicator = false
        }
    }

    // MARK: - HasBody Protocol

    /// The QuickLayout content rendered by the scroll view.
    @LayoutBuilder
    open var body: Layout {
        if contentElements.isEmpty {
            EmptyLayout()
        } else {
            axisLayout
        }
    }

    @LayoutBuilder
    private var axisLayout: Layout {
        switch axis {
        case .vertical:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(contentElements)
            }
        case .horizontal:
            HStack(alignment: .top, spacing: 0) {
                ForEach(contentElements)
            }
        }
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()

        // Calculate the proposed size for content
        let proposedSize = calculateProposedSize()

        // Calculate content size using QuickLayout
        let contentSize = _QuickLayoutViewImplementation.sizeThatFits(
            self,
            size: proposedSize
        ) ?? .zero

        let layoutDirection: LayoutDirection = effectiveUserInterfaceLayoutDirection == .rightToLeft
            ? .rightToLeft
            : .leftToRight

        // Apply layout with proper alignment
        body.applyFrame(
            CGRect(origin: .zero, size: contentSize),
            alignment: contentAlignment,
            layoutDirection: layoutDirection
        )

        // Update scrollView's contentSize
        if self.contentSize != contentSize {
            self.contentSize = contentSize
        }

        applyPendingScrollRequestIfPossible()
    }

    // MARK: - Private Helpers

    private func calculateProposedSize() -> CGSize {
        let frameSize = frame.size

        switch axis {
        case .vertical:
            // Vertical scrolling: fix width, infinite height
            return CGSize(width: frameSize.width, height: .infinity)
        case .horizontal:
            // Horizontal scrolling: infinite width, fix height
            return CGSize(width: .infinity, height: frameSize.height)
        }
    }

    // MARK: - Public Methods

    /// Replaces the elements displayed in the scroll view.
    ///
    /// - Parameter contentElements: The elements to display.
    open func setContentElements(_ contentElements: [Element]) {
        self.contentElements = contentElements
    }

    /// Appends elements to the scroll view.
    ///
    /// - Parameter contentElements: The elements to append.
    open func appendContentElements(_ contentElements: [Element]) {
        self.contentElements.append(contentsOf: contentElements)
    }

    /// Removes all elements from the scroll view.
    open func removeAllContentElements() {
        self.contentElements.removeAll()
    }

    /// Replaces the scroll content with content produced by a builder.
    ///
    /// - Parameters:
    ///   - axis: The scroll axis to apply. Pass `nil` to keep the current axis.
    ///   - options: Options controlling layout and visible-position behavior.
    ///   - content: A builder closure that returns the new elements.
    open func updateContent(
        axis: QuickLayout.Axis? = nil,
        options: QuickLayoutScrollContentUpdateOptions = [.layoutImmediately],
        @FastArrayBuilder<Element> content: () -> [Element]
    ) {
        let previousContentSize = contentSize
        let previousContentOffset = contentOffset

        if let axis {
            self.axis = axis
        }
        contentElements = content()

        if options.contains(.layoutImmediately) || options.contains(.preserveVisiblePosition) {
            setNeedsLayout()
            layoutIfNeeded()
        }

        guard options.contains(.preserveVisiblePosition) else { return }

        switch self.axis {
        case .vertical:
            let delta = contentSize.height - previousContentSize.height
            contentOffset = CGPoint(x: previousContentOffset.x, y: previousContentOffset.y + delta)
        case .horizontal:
            let delta = contentSize.width - previousContentSize.width
            contentOffset = CGPoint(x: previousContentOffset.x + delta, y: previousContentOffset.y)
        }
    }

    /// Appends builder-produced content to the current elements.
    ///
    /// - Parameters:
    ///   - options: Options controlling layout and visible-position behavior.
    ///   - content: A builder closure that returns the appended elements.
    open func appendContent(
        options: QuickLayoutScrollContentUpdateOptions = [.layoutImmediately],
        @FastArrayBuilder<Element> content: () -> [Element]
    ) {
        let appendedElements = content()
        updateContent(axis: axis, options: options) {
            ForEach(contentElements + appendedElements)
        }
    }
}

extension QuickLayoutScrollView {

    /// Creates a vertically scrolling view.
    ///
    /// - Parameter content: A builder closure that returns the elements to
    ///   display.
    /// - Returns: A scroll view configured for vertical scrolling.
    public static func vertical(@FastArrayBuilder<Element> content: () -> [Element]) -> QuickLayoutScrollView {
        let scrollView = QuickLayoutScrollView()
        scrollView.axis = .vertical
        scrollView.contentElements = content()
        return scrollView
    }

    /// Creates a horizontally scrolling view.
    ///
    /// - Parameter content: A builder closure that returns the elements to
    ///   display.
    /// - Returns: A scroll view configured for horizontal scrolling.
    public static func horizontal(@FastArrayBuilder<Element> content: () -> [Element]) -> QuickLayoutScrollView {
        let scrollView = QuickLayoutScrollView()
        scrollView.axis = .horizontal
        scrollView.contentElements = content()
        return scrollView
    }
}

extension QuickLayoutScrollView {

    /// Scrolls to the beginning of the content.
    ///
    /// - Parameter animated: Pass `true` to animate the change.
    public func scrollToBeginning(animated: Bool = true) {
        performScrollRequest(.beginning(animated: animated))
    }

    /// Scrolls to the end of the content.
    ///
    /// For vertical scrolling, the receiver scrolls to the bottom edge. For
    /// horizontal scrolling, it scrolls to the trailing edge.
    ///
    /// - Parameter animated: Pass `true` to animate the change.
    public func scrollToEnd(animated: Bool = true) {
        performScrollRequest(.end(animated: animated))
    }

    /// Scrolls to the specified edge.
    ///
    /// - Parameters:
    ///   - edge: The edge to scroll to.
    ///   - animated: Pass `true` to animate the change.
    public func scrollTo(_ edge: QuickLayoutScrollEdge, animated: Bool = true) {
        performScrollRequest(.edge(edge, animated: animated))
    }

    private func performScrollRequest(_ request: PendingScrollRequest) {
        // Force layout to ensure contentSize is up to date
        layoutIfNeeded()

        guard let edge = edge(for: request),
              canResolveScrollOffset(for: edge) else {
            pendingScrollRequest = request
            return
        }

        setContentOffset(targetOffset(for: edge), requestedAnimated: request.animated)
    }

    private func targetOffset(for edge: QuickLayoutScrollEdge) -> CGPoint {
        // Get the effective contentInset (including safe area)
        let adjustedInset = adjustedContentInset

        switch edge {
        case .top:
            return CGPoint(x: contentOffset.x, y: -adjustedInset.top)

        case .bottom:
            let offsetY = contentSize.height - bounds.height + adjustedInset.bottom
            return CGPoint(x: contentOffset.x, y: max(-adjustedInset.top, offsetY))

        case .leading:
            return CGPoint(x: horizontalOffset(for: .leading, adjustedInset: adjustedInset), y: contentOffset.y)

        case .trailing:
            return CGPoint(x: horizontalOffset(for: .trailing, adjustedInset: adjustedInset), y: contentOffset.y)
        }
    }

    private func applyPendingScrollRequestIfPossible() {
        guard let pendingScrollRequest,
              let edge = edge(for: pendingScrollRequest),
              canResolveScrollOffset(for: edge) else {
            return
        }

        self.pendingScrollRequest = nil
        setContentOffset(
            targetOffset(for: edge),
            requestedAnimated: pendingScrollRequest.animated
        )
    }

    private func edge(for request: PendingScrollRequest) -> QuickLayoutScrollEdge? {
        switch request {
        case .edge(let edge, _):
            return edge
        case .beginning:
            return axis == .vertical ? .top : .leading
        case .end:
            return axis == .vertical ? .bottom : .trailing
        }
    }

    private func canResolveScrollOffset(for edge: QuickLayoutScrollEdge) -> Bool {
        switch edge {
        case .top, .bottom:
            bounds.height > 0 && contentSize.height > 0
        case .leading, .trailing:
            bounds.width > 0 && contentSize.width > 0
        }
    }

    private func horizontalOffset(
        for edge: QuickLayoutScrollEdge,
        adjustedInset: UIEdgeInsets
    ) -> CGFloat {
        let minimumOffset = -adjustedInset.left
        let maximumOffset = max(
            minimumOffset,
            contentSize.width - bounds.width + adjustedInset.right
        )
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft

        switch (edge, isRightToLeft) {
        case (.leading, false), (.trailing, true):
            return minimumOffset
        case (.leading, true), (.trailing, false):
            return maximumOffset
        default:
            return contentOffset.x
        }
    }

    private func setContentOffset(_ contentOffset: CGPoint, requestedAnimated animated: Bool) {
        guard !animated else {
            setContentOffset(contentOffset, animated: true)
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            setContentOffset(contentOffset, animated: false)
            layer.removeAnimation(forKey: "bounds")
            layer.removeAnimation(forKey: "position")
        }
        CATransaction.commit()
    }
}

private enum PendingScrollRequest {
    case edge(QuickLayoutScrollEdge, animated: Bool)
    case beginning(animated: Bool)
    case end(animated: Bool)

    var animated: Bool {
        switch self {
        case .edge(_, let animated), .beginning(let animated), .end(let animated):
            return animated
        }
    }
}
