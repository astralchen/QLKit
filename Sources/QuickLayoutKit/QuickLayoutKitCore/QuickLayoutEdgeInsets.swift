import CoreGraphics
import QuickLayout

extension QuickLayout.EdgeInsets {

    /// The maximum horizontal inset.
    ///
    /// This value is the larger of the receiver's leading and trailing insets.
    public var maximumHorizontalInset: CGFloat {
        max(leading, trailing)
    }

    /// The maximum vertical inset.
    ///
    /// This value is the larger of the receiver's top and bottom insets.
    public var maximumVerticalInset: CGFloat {
        max(top, bottom)
    }
}
