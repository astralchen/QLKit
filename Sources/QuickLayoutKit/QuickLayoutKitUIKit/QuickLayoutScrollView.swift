//
//  QuickLayoutScrollView.swift
//  QuickLayoutKit
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout

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

        // Get the alignment based on scroll axis
        let alignment = contentAlignment

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
            alignment: alignment
        )

        // Update scrollView's contentSize
        if self.contentSize != contentSize {
            self.contentSize = contentSize
        }
    }

    // MARK: - Private Helpers

    private var contentAlignment: Alignment {
        switch axis {
        case .vertical:
            return .topLeading
        case .horizontal:
            return .topLeading
        }
    }

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
        setContentOffset(.zero, animated: animated)
    }

    /// Scrolls to the end of the content.
    ///
    /// For vertical scrolling, the receiver scrolls to the bottom edge. For
    /// horizontal scrolling, it scrolls to the trailing edge.
    ///
    /// - Parameter animated: Pass `true` to animate the change.
    public func scrollToEnd(animated: Bool = true) {
        // Force layout to ensure contentSize is up to date
        layoutIfNeeded()

        // Get the effective contentInset (including safe area)
        let adjustedInset = adjustedContentInset

        let bottomOffset: CGPoint
        switch axis {
        case .vertical:
            // Calculate the offset to scroll to the bottom
            let offsetY = contentSize.height - bounds.height + adjustedInset.bottom
            bottomOffset = CGPoint(x: contentOffset.x, y: max(-adjustedInset.top, offsetY))

        case .horizontal:
            // Calculate the offset to scroll to the far right
            let offsetX = contentSize.width - bounds.width + adjustedInset.right
            bottomOffset = CGPoint(x: max(-adjustedInset.left, offsetX), y: contentOffset.y)
        }

        setContentOffset(bottomOffset, animated: animated)
    }
}
