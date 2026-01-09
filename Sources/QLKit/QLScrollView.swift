//
//  QLScrollView.swift
//  QLKit
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout

/// A scrollable view that conforms to QuickLayout's HasBody protocol
///
/// Usage:
/// ```swift
/// let scrollView = QLScrollView()
/// scrollView.axis = .vertical
/// scrollView.children = [label1, label2, label3]
/// ```
open class QLScrollView: UIScrollView, HasBody {

    // MARK: - Public Properties

    /// The scroll direction (vertical or horizontal)
    open var axis: QuickLayout.Axis = .vertical {
        didSet {
            if axis != oldValue {
                configureScrollBehavior()
                setNeedsLayout()
            }
        }
    }

    /// The child elements to be laid out in the scroll view
    open var children: [Element] = [] {
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

    /// Configures the scroll view's behavior based on the current axis.
    ///
    /// This method sets properties like `alwaysBounceVertical`, `alwaysBounceHorizontal`,
    /// and scroll indicators to match the desired scroll direction.
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

    @LayoutBuilder
    open var body: Layout {
        if children.isEmpty {
            EmptyLayout()
        } else {
            axisLayout
        }
    }

    /// Generates the layout for the current axis.
    ///
    /// - Returns: A `VStack` for vertical axis or `HStack` for horizontal axis, containing all children.
    @LayoutBuilder
    private var axisLayout: Layout {
        switch axis {
        case .vertical:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(children)
            }
        case .horizontal:
            HStack(alignment: .top, spacing: 0) {
                ForEach(children)
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

    /// Returns the appropriate alignment based on scroll axis
    private var contentAlignment: Alignment {
        switch axis {
        case .vertical:
            return .topLeading
        case .horizontal:
            return .topLeading
        }
    }

    /// Calculates the proposed size for content based on scroll axis
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

    /// Updates the scroll view with new children
    /// - Parameter children: The new array of child elements
    open func setChildren(_ children: [Element]) {
        self.children = children
    }

    /// Appends children to the existing array
    /// - Parameter children: The children to append
    open func appendChildren(_ children: [Element]) {
        self.children.append(contentsOf: children)
    }

    /// Removes all children
    open func removeAllChildren() {
        self.children.removeAll()
    }
}

// MARK: - Convenience Extensions

extension QLScrollView {

    /// Creates a vertical scroll view with children
    /// - Parameter children: The child elements
    /// - Returns: A configured QLScrollView
    public static func vertical(@FastArrayBuilder<Element> children: () -> [Element]) -> QLScrollView {
        let scrollView = QLScrollView()
        scrollView.axis = .vertical
        scrollView.children = children()
        return scrollView
    }

    /// Creates a horizontal scroll view with children
    /// - Parameter children: The child elements
    /// - Returns: A configured QLScrollView
    public static func horizontal(@FastArrayBuilder<Element> children: () -> [Element]) -> QLScrollView {
        let scrollView = QLScrollView()
        scrollView.axis = .horizontal
        scrollView.children = children()
        return scrollView
    }

    /// Configures scroll indicators
    @discardableResult
    public func showsIndicators(_ shows: Bool) -> Self {
        showsVerticalScrollIndicator = shows
        showsHorizontalScrollIndicator = shows
        return self
    }

    /// Configures paging
    @discardableResult
    public func paging(_ enabled: Bool) -> Self {
        isPagingEnabled = enabled
        return self
    }

    /// Configures bouncing
    @discardableResult
    public func bounces(_ enabled: Bool) -> Self {
        bounces = enabled
        return self
    }

    /// Configures content inset
    @discardableResult
    public func contentInset(_ inset: UIEdgeInsets) -> Self {
        contentInset = inset
        return self
    }
}

extension QLScrollView {

    /// Scrolls to the top
    public func scrollToTop(animated: Bool = true) {
        setContentOffset(.zero, animated: animated)
    }

    /// Scrolls to the bottom
    public func scrollToBottom(animated: Bool = true) {
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
