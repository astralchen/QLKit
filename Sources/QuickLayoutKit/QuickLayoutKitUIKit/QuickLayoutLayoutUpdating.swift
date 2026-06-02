import UIKit

/// A type that can invalidate and immediately lay out QuickLayout content.
@MainActor
public protocol QuickLayoutLayoutUpdating: AnyObject {

    /// Invalidates the hosted QuickLayout content.
    func setNeedsLayoutUpdate()

    /// Lays out the hosted QuickLayout content immediately if needed.
    func layoutIfNeeded()
}

extension QuickLayoutLayoutUpdating where Self: UIView {

    /// Invalidates and lays out QuickLayout content inside a UIKit animation.
    ///
    /// - Parameters:
    ///   - duration: The animation duration.
    ///   - delay: The delay before the animation starts.
    ///   - options: UIKit animation options.
    ///   - animations: Additional animations to run with the layout update.
    ///   - completion: A completion handler called when the animation finishes.
    public func performLayoutUpdate(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = [],
        animations: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        setNeedsLayoutUpdate()
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: options,
            animations: {
                animations?()
                self.layoutIfNeeded()
            },
            completion: completion
        )
    }
}

extension QuickLayoutLayoutUpdating where Self: UIViewController {

    /// Invalidates and lays out QuickLayout content inside a UIKit animation.
    ///
    /// - Parameters:
    ///   - duration: The animation duration.
    ///   - delay: The delay before the animation starts.
    ///   - options: UIKit animation options.
    ///   - animations: Additional animations to run with the layout update.
    ///   - completion: A completion handler called when the animation finishes.
    public func performLayoutUpdate(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = [],
        animations: (() -> Void)? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        setNeedsLayoutUpdate()
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: options,
            animations: {
                animations?()
                self.layoutIfNeeded()
            },
            completion: completion
        )
    }
}
