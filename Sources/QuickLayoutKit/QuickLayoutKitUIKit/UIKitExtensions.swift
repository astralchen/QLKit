import UIKit
import QuickLayout

extension UIView {

    /// The view's safe area insets expressed as QuickLayout edge insets.
    ///
    /// The leading and trailing values reflect the view's effective user
    /// interface layout direction.
    ///
    /// Query this value after the view has been laid out, such as from
    /// `viewDidLayoutSubviews()`.
    public var quickLayoutSafeAreaInsets: QuickLayout.EdgeInsets {
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft

        return .init(
            top: safeAreaInsets.top,
            leading: isRTL ? safeAreaInsets.right : safeAreaInsets.left,
            bottom: safeAreaInsets.bottom,
            trailing: isRTL ? safeAreaInsets.left : safeAreaInsets.right
        )
    }
}

/// Creates a QuickLayout expression by mapping views to layout elements.
///
/// Use this function inside a layout builder when you need to produce one
/// element for each view in a collection.
///
/// - Parameters:
///   - list: The views to iterate over.
///   - map: A closure that returns the element for a view.
/// - Returns: A fast expression that contains the mapped elements in order.
public func ForEach<T>(_ list: [T], map: (T) -> Element) -> FastExpression where T: UIView {
    BlockExpression(expressions: list.map { ValueExpression<Element>(value: map($0)) })
}


extension UICollectionViewCell {

    /// Returns the sizing flexibility for the cell on the specified axis.
    ///
    /// Override this method in subclasses to describe whether the cell's width
    /// or height is fixed by the collection view layout, partially constrained,
    /// or fully determined by its content.
    ///
    /// - Parameter axis: The axis to query.
    /// - Returns: The sizing flexibility for the specified axis.
    @objc open func quickLayoutFlexibility(for axis: Axis) -> Flexibility {
        .fullyFlexible
    }

    /// Returns the layout limit for a proposed length and flexibility.
    ///
    /// Use this value when measuring collection view cells whose final size is
    /// computed by QuickLayout. Fixed sizes use the proposed value, partially
    /// flexible sizes use at least the minimum value, and fully flexible sizes
    /// use an unconstrained limit.
    ///
    /// - Parameters:
    ///   - proposed: The length proposed by the parent layout.
    ///   - minimum: The minimum length to use for partial flexibility.
    ///   - flexibility: The sizing flexibility for the measured axis.
    /// - Returns: The length limit to use during layout measurement.
    public func quickLayoutSizeLimit(
        proposed: CGFloat,
        minimum: CGFloat = 0,
        flexibility: Flexibility
    ) -> CGFloat {

        switch flexibility {
        case .fixedSize:
            return proposed

        case .partial:
            return max(minimum, proposed)

        case .fullyFlexible:
            return .infinity
        }
    }
}

extension UICollectionViewCell {

    /// Returns the layout limit for a proposed size.
    ///
    /// The returned size applies the cell's horizontal and vertical flexibility
    /// independently.
    ///
    /// - Parameter size: The size proposed by the parent layout.
    /// - Returns: The size limit to use during layout measurement.
    public func quickLayoutSizeLimit(
        proposed size: CGSize
    ) -> CGSize {
        CGSize(
            width: quickLayoutSizeLimit(
                proposed: size.width,
                flexibility: quickLayoutFlexibility(for: .horizontal)
            ),
            height: quickLayoutSizeLimit(
                proposed: size.height,
                flexibility: quickLayoutFlexibility(for: .vertical)
            )
        )
    }
}
