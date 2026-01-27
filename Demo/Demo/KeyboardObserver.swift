//
//  KeyboardObserver.swift
//  Demo
//
//  Created by Sondra on 2026/1/27.
//

import UIKit
import Combine

// MARK: - 可复用的 Keyboard Observer
class KeyboardObserver: ObservableObject {

    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    private func setupObservers() {
        // 监听键盘显示
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return keyboardFrame.height
            }
            .sink { [weak self] height in
                self?.keyboardHeight = height
                self?.isKeyboardVisible = true
            }
            .store(in: &cancellables)

        // 监听键盘隐藏
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)

        // 监听键盘高度变化 (orientation change 等)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return keyboardFrame.height
            }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
    }

    // 获取键盘动画信息
    static func getAnimationInfo(from notification: Notification) -> (duration: TimeInterval, curve: UIView.AnimationOptions)? {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return nil
        }
        let curve = UIView.AnimationOptions(rawValue: curveValue << 16)
        return (duration, curve)
    }
}

// MARK: - 带动画的 Keyboard Observer
class AnimatedKeyboardObserver: ObservableObject {

    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false

    var animationDuration: TimeInterval = 0.3
    var animationCurve: UIView.AnimationOptions = .curveEaseInOut

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardShow(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardHide(notification)
            }
            .store(in: &cancellables)
    }

    private func handleKeyboardShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        // 提取动画信息
        if let animInfo = KeyboardObserver.getAnimationInfo(from: notification) {
            animationDuration = animInfo.duration
            animationCurve = animInfo.curve
        }

        keyboardHeight = keyboardFrame.height
        isKeyboardVisible = true
    }

    private func handleKeyboardHide(_ notification: Notification) {
        if let animInfo = KeyboardObserver.getAnimationInfo(from: notification) {
            animationDuration = animInfo.duration
            animationCurve = animInfo.curve
        }

        keyboardHeight = 0
        isKeyboardVisible = false
    }
}

// MARK: - Property Wrapper 版本 (更优雅的使用方式)
@propertyWrapper
class KeyboardResponsive {
    private let observer = KeyboardObserver()
    private var cancellable: AnyCancellable?

    var wrappedValue: CGFloat = 0

    var projectedValue: AnyPublisher<CGFloat, Never> {
        observer.$keyboardHeight.eraseToAnyPublisher()
    }

    init(wrappedValue: CGFloat = 0) {
        self.wrappedValue = wrappedValue

        cancellable = observer.$keyboardHeight
            .sink { [weak self] height in
                self?.wrappedValue = height
            }
    }
}
