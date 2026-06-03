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

/// A semantic anchor used when preserving visible scroll position.
public enum QuickLayoutScrollAnchor {

    /// Preserve the visible leading edge using the measured content-size delta.
    case visibleLeadingEdge

    /// Preserve the visible center using the measured content-size delta.
    case visibleCenter

    /// Preserve the screen position of a specific view.
    case view(UIView)
}

/// A scroll view that lays out QuickLayout elements as its content.
///
/// `QuickLayoutScrollView` measures its `contentElements` with QuickLayout and
/// updates its `contentSize` during layout.
open class QuickLayoutScrollView: UIScrollView, HasBody {

    /// Runtime events emitted by `QuickLayoutScrollView`.
    public enum Event {

        /// The measured content size changed during layout.
        case contentSizeChanged(old: CGSize, new: CGSize)

        /// A deferred scroll request was applied after content was measured.
        case didApplyPendingScroll(edge: QuickLayoutScrollEdge, animated: Bool)

        /// A content update preserved the requested visible position.
        case didPreserveVisiblePosition(anchor: QuickLayoutScrollAnchor)
    }

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

    /// Overrides the effective QuickLayout direction used for content layout
    /// and leading/trailing scroll offsets.
    ///
    /// The default value, `nil`, derives the direction from UIKit's effective
    /// user interface layout direction.
    open var quickLayoutDirectionOverride: LayoutDirection? {
        didSet {
            if quickLayoutDirectionOverride != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// Receives scroll measurement and content-update events.
    open var scrollEventHandler: ((Event) -> Void)?

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

        let oldContentSize = self.contentSize

        // Apply layout with proper alignment
        body.applyFrame(
            CGRect(origin: .zero, size: contentSize),
            alignment: contentAlignment,
            layoutDirection: resolvedQuickLayoutDirection
        )

        // Update scrollView's contentSize
        if self.contentSize != contentSize {
            self.contentSize = contentSize
            scrollEventHandler?(.contentSizeChanged(old: oldContentSize, new: contentSize))
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

    private var resolvedQuickLayoutDirection: LayoutDirection {
        quickLayoutDirectionOverride ?? quickLayoutDirection
    }

    private func applyContentUpdate(
        axis: QuickLayout.Axis?,
        options: QuickLayoutScrollContentUpdateOptions,
        preserving anchor: QuickLayoutScrollAnchor?,
        @FastArrayBuilder<Element> content: () -> [Element]
    ) {
        let capturedAnchor = anchor.map { captureScrollAnchor($0) }
        let shouldPreserveAnchor = capturedAnchor != nil || options.contains(.preserveVisiblePosition)

        if let axis {
            self.axis = axis
        }
        contentElements = content()

        if options.contains(.layoutImmediately) || shouldPreserveAnchor {
            setNeedsLayout()
            layoutIfNeeded()
        }

        guard shouldPreserveAnchor else { return }

        if let anchor, let capturedAnchor {
            restoreScrollAnchor(capturedAnchor)
            scrollEventHandler?(.didPreserveVisiblePosition(anchor: anchor))
        }
    }

    private func captureScrollAnchor(_ anchor: QuickLayoutScrollAnchor) -> CapturedScrollAnchor {
        let fallback = CapturedScrollAnchor.fallback(
            axis: axis,
            contentSize: contentSize,
            contentOffset: contentOffset
        )

        guard case .view(let view) = anchor,
              view.superview != nil || view === self else {
            return fallback
        }

        let rect = view.convert(view.bounds, to: self)
        let contentPosition: CGFloat
        let visiblePosition: CGFloat

        switch axis {
        case .vertical:
            contentPosition = rect.minY
            visiblePosition = rect.minY - contentOffset.y
        case .horizontal:
            contentPosition = rect.minX
            visiblePosition = rect.minX - contentOffset.x
        }

        return .view(
            view,
            axis: axis,
            contentPosition: contentPosition,
            visiblePosition: visiblePosition,
            fallback: fallback
        )
    }

    private func restoreScrollAnchor(_ capturedAnchor: CapturedScrollAnchor) {
        switch capturedAnchor {
        case .fallback(let axis, let oldContentSize, let oldContentOffset):
            restoreFallbackPosition(axis: axis, oldContentSize: oldContentSize, oldContentOffset: oldContentOffset)

        case .view(let view, let axis, _, let visiblePosition, let fallback):
            guard view.superview != nil || view === self else {
                restoreScrollAnchor(fallback)
                return
            }

            let rect = view.convert(view.bounds, to: self)
            var targetOffset = contentOffset

            switch axis {
            case .vertical:
                targetOffset.y = rect.minY - visiblePosition
            case .horizontal:
                targetOffset.x = rect.minX - visiblePosition
            }

            contentOffset = clampedContentOffset(targetOffset)
        }
    }

    private func restoreFallbackPosition(
        axis: QuickLayout.Axis,
        oldContentSize: CGSize,
        oldContentOffset: CGPoint
    ) {
        var targetOffset = oldContentOffset

        switch axis {
        case .vertical:
            let delta = contentSize.height - oldContentSize.height
            targetOffset.y = oldContentOffset.y + delta
        case .horizontal:
            let delta = contentSize.width - oldContentSize.width
            targetOffset.x = oldContentOffset.x + delta
        }

        contentOffset = clampedContentOffset(targetOffset)
    }

    private func clampedContentOffset(_ proposedOffset: CGPoint) -> CGPoint {
        let adjustedInset = adjustedContentInset
        let minimumX = -adjustedInset.left
        let maximumX = max(
            minimumX,
            contentSize.width - bounds.width + adjustedInset.right
        )
        let minimumY = -adjustedInset.top
        let maximumY = max(
            minimumY,
            contentSize.height - bounds.height + adjustedInset.bottom
        )

        return CGPoint(
            x: min(max(proposedOffset.x, minimumX), maximumX),
            y: min(max(proposedOffset.y, minimumY), maximumY)
        )
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
        applyContentUpdate(axis: axis, options: options, preserving: nil, content: content)
    }

    /// Replaces the scroll content while preserving a semantic visible anchor.
    ///
    /// - Parameters:
    ///   - axis: The scroll axis to apply. Pass `nil` to keep the current axis.
    ///   - options: Options controlling layout and visible-position behavior.
    ///   - anchor: The visible anchor to preserve.
    ///   - content: A builder closure that returns the new elements.
    open func updateContent(
        axis: QuickLayout.Axis? = nil,
        options: QuickLayoutScrollContentUpdateOptions = [],
        preserving anchor: QuickLayoutScrollAnchor,
        @FastArrayBuilder<Element> content: () -> [Element]
    ) {
        applyContentUpdate(axis: axis, options: options, preserving: anchor, content: content)
    }

    /// Prepends builder-produced content to the current elements.
    ///
    /// - Parameters:
    ///   - options: Options controlling layout and visible-position behavior.
    ///   - anchor: The visible anchor to preserve.
    ///   - content: A builder closure that returns the prepended elements.
    open func prependContent(
        options: QuickLayoutScrollContentUpdateOptions = [.preserveVisiblePosition],
        preserving anchor: QuickLayoutScrollAnchor = .visibleLeadingEdge,
        @FastArrayBuilder<Element> content: () -> [Element]
    ) {
        let prependedElements = content()
        updateContent(axis: axis, options: options, preserving: anchor) {
            ForEach(prependedElements + contentElements)
        }
    }

    /// Replaces the scroll content with content produced by a builder.
    ///
    /// - Parameters:
    ///   - axis: The scroll axis to apply. Pass `nil` to keep the current axis.
    ///   - options: Options controlling immediate layout.
    ///   - content: A builder closure that returns the new elements.
    open func replaceContent(
        axis: QuickLayout.Axis? = nil,
        options: QuickLayoutScrollContentUpdateOptions = [.layoutImmediately],
        @FastArrayBuilder<Element> content: () -> [Element]
    ) {
        applyContentUpdate(axis: axis, options: options, preserving: nil, content: content)
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
        scrollEventHandler?(.didApplyPendingScroll(edge: edge, animated: pendingScrollRequest.animated))
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
        let isRightToLeft = resolvedQuickLayoutDirection == .rightToLeft

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

private indirect enum CapturedScrollAnchor {
    case fallback(axis: QuickLayout.Axis, oldContentSize: CGSize, oldContentOffset: CGPoint)
    case view(
        UIView,
        axis: QuickLayout.Axis,
        contentPosition: CGFloat,
        visiblePosition: CGFloat,
        fallback: CapturedScrollAnchor
    )

    static func fallback(
        axis: QuickLayout.Axis,
        contentSize: CGSize,
        contentOffset: CGPoint
    ) -> CapturedScrollAnchor {
        .fallback(axis: axis, oldContentSize: contentSize, oldContentOffset: contentOffset)
    }
}
