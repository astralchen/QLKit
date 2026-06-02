import Combine
import UIKit

/// A parsed UIKit keyboard notification.
public struct QuickLayoutKeyboardContext: Equatable, Sendable {

    /// The keyboard frame at the end of the transition.
    public let endFrame: CGRect

    /// The keyboard animation duration.
    public let animationDuration: TimeInterval

    /// UIKit animation options matching the keyboard transition.
    public let animationOptions: UIView.AnimationOptions

    /// A Boolean value indicating whether the keyboard is visible.
    public let isVisible: Bool

    /// The effective keyboard height.
    public var height: CGFloat {
        isVisible ? endFrame.height : 0
    }

    /// Creates a context from explicit values.
    public init(
        endFrame: CGRect,
        animationDuration: TimeInterval,
        animationOptions: UIView.AnimationOptions,
        isVisible: Bool
    ) {
        self.endFrame = endFrame
        self.animationDuration = animationDuration
        self.animationOptions = animationOptions
        self.isVisible = isVisible
    }

    /// Creates a keyboard context from a UIKit keyboard notification.
    ///
    /// - Parameter notification: A keyboard notification from `UIResponder`.
    public init?(notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return nil
        }

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        let options = curveValue.map { UIView.AnimationOptions(rawValue: $0 << 16) } ?? .curveEaseInOut
        let visible = notification.name != UIResponder.keyboardWillHideNotification

        self.init(
            endFrame: frame,
            animationDuration: duration,
            animationOptions: options,
            isVisible: visible
        )
    }

    /// An empty hidden-keyboard context.
    public static let hidden = QuickLayoutKeyboardContext(
        endFrame: .zero,
        animationDuration: 0.25,
        animationOptions: .curveEaseInOut,
        isVisible: false
    )
}

/// Observes UIKit keyboard notifications and publishes parsed keyboard context.
@MainActor
public final class QuickLayoutKeyboardObserver: ObservableObject {

    /// The latest keyboard context.
    @Published public private(set) var context: QuickLayoutKeyboardContext = .hidden

    /// The latest keyboard height.
    public var keyboardHeight: CGFloat {
        context.height
    }

    /// A Boolean value indicating whether the keyboard is visible.
    public var isKeyboardVisible: Bool {
        context.isVisible
    }

    private var cancellables: Set<AnyCancellable> = []

    public init(notificationCenter: NotificationCenter = .default) {
        let notifications = [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillHideNotification,
            UIResponder.keyboardWillChangeFrameNotification,
        ]

        for name in notifications {
            notificationCenter.publisher(for: name)
                .compactMap(QuickLayoutKeyboardContext.init(notification:))
                .sink { [weak self] context in
                    self?.context = context
                }
                .store(in: &cancellables)
        }
    }
}

/// Applies keyboard insets to a scroll view and keeps the active input visible.
@MainActor
public final class QuickLayoutKeyboardAvoider {

    private weak var scrollView: UIScrollView?
    private let observer: QuickLayoutKeyboardObserver
    private var cancellables: Set<AnyCancellable> = []
    private weak var activeView: UIView?
    private var baseContentInset: UIEdgeInsets
    private var baseVerticalScrollIndicatorInsets: UIEdgeInsets
    private var baseHorizontalScrollIndicatorInsets: UIEdgeInsets

    /// Creates a keyboard avoider for a scroll view.
    ///
    /// - Parameters:
    ///   - scrollView: The scroll view whose insets should track the keyboard.
    ///   - observer: The keyboard observer to use.
    public init(
        scrollView: UIScrollView,
        observer: QuickLayoutKeyboardObserver = QuickLayoutKeyboardObserver()
    ) {
        self.scrollView = scrollView
        self.observer = observer
        self.baseContentInset = scrollView.contentInset
        self.baseVerticalScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        self.baseHorizontalScrollIndicatorInsets = scrollView.horizontalScrollIndicatorInsets

        observer.$context
            .sink { [weak self] context in
                self?.apply(context)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)
            .merge(with: NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification))
            .sink { [weak self] notification in
                self?.activeView = notification.object as? UIView
                self?.scrollActiveViewIntoVisibleArea(animated: true)
            }
            .store(in: &cancellables)
    }

    /// Captures the scroll view's current insets as the base values that
    /// keyboard height should be added to.
    public func captureCurrentInsetsAsBase() {
        guard let scrollView else { return }
        baseContentInset = scrollView.contentInset
        baseVerticalScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        baseHorizontalScrollIndicatorInsets = scrollView.horizontalScrollIndicatorInsets
    }

    /// Applies a keyboard context immediately.
    ///
    /// - Parameter context: The keyboard context to apply.
    public func apply(_ context: QuickLayoutKeyboardContext) {
        guard let scrollView else { return }

        let keyboardHeight = context.isVisible ? context.height : 0
        var contentInset = baseContentInset
        var verticalIndicatorInsets = baseVerticalScrollIndicatorInsets
        var horizontalIndicatorInsets = baseHorizontalScrollIndicatorInsets

        contentInset.bottom = baseContentInset.bottom + keyboardHeight
        verticalIndicatorInsets.bottom = baseVerticalScrollIndicatorInsets.bottom + keyboardHeight
        horizontalIndicatorInsets.bottom = baseHorizontalScrollIndicatorInsets.bottom + keyboardHeight

        UIView.animate(
            withDuration: context.animationDuration,
            delay: 0,
            options: context.animationOptions,
            animations: {
                scrollView.contentInset = contentInset
                scrollView.verticalScrollIndicatorInsets = verticalIndicatorInsets
                scrollView.horizontalScrollIndicatorInsets = horizontalIndicatorInsets
                scrollView.superview?.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.scrollActiveViewIntoVisibleArea(animated: context.isVisible)
            }
        )
    }

    /// Sets the view that should remain visible above the keyboard.
    ///
    /// - Parameter view: The active input or focus view.
    public func setActiveView(_ view: UIView?) {
        activeView = view
    }

    /// Scrolls the active view into the visible region.
    ///
    /// - Parameter animated: Pass `true` to animate the scroll.
    public func scrollActiveViewIntoVisibleArea(animated: Bool) {
        guard
            let scrollView,
            let activeView,
            activeView.window != nil || activeView.superview != nil
        else {
            return
        }

        let targetRect = activeView.convert(activeView.bounds, to: scrollView).insetBy(dx: 0, dy: -12)
        scrollView.scrollRectToVisible(targetRect, animated: animated)
    }
}
