//
//  QuickLayoutScrollView.swift
//  QuickLayoutKit
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
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

        // Apply layout with proper alignment
        body.applyFrame(
            CGRect(origin: .zero, size: contentSize),
            alignment: contentAlignment
        )

        // Update scrollView's contentSize
        if self.contentSize != contentSize {
            self.contentSize = contentSize
        }
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
        scrollTo(axis == .vertical ? .top : .leading, animated: animated)
    }

    /// Scrolls to the end of the content.
    ///
    /// For vertical scrolling, the receiver scrolls to the bottom edge. For
    /// horizontal scrolling, it scrolls to the trailing edge.
    ///
    /// - Parameter animated: Pass `true` to animate the change.
    public func scrollToEnd(animated: Bool = true) {
        scrollTo(axis == .vertical ? .bottom : .trailing, animated: animated)
    }

    /// Scrolls to the specified edge.
    ///
    /// - Parameters:
    ///   - edge: The edge to scroll to.
    ///   - animated: Pass `true` to animate the change.
    public func scrollTo(_ edge: QuickLayoutScrollEdge, animated: Bool = true) {
        // Force layout to ensure contentSize is up to date
        layoutIfNeeded()

        // Get the effective contentInset (including safe area)
        let adjustedInset = adjustedContentInset

        let targetOffset: CGPoint
        switch edge {
        case .top:
            targetOffset = CGPoint(x: contentOffset.x, y: -adjustedInset.top)

        case .bottom:
            let offsetY = contentSize.height - bounds.height + adjustedInset.bottom
            targetOffset = CGPoint(x: contentOffset.x, y: max(-adjustedInset.top, offsetY))

        case .leading:
            targetOffset = CGPoint(x: -adjustedInset.left, y: contentOffset.y)

        case .trailing:
            let offsetX = contentSize.width - bounds.width + adjustedInset.right
            targetOffset = CGPoint(x: max(-adjustedInset.left, offsetX), y: contentOffset.y)
        }

        setContentOffset(targetOffset, animated: animated)
    }
}
