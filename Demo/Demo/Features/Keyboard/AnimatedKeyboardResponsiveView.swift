//
//  AnimatedKeyboardResponsiveView.swift
//  Demo
//
//  Created by Sondra on 2026/1/27.
//
import UIKit
import QuickLayout
import QuickLayoutKit
import Combine


@QuickLayout
class AnimatedKeyboardResponsiveView: UIView {

    let textField = UITextField()
    let submitButton = UIButton(type: .system)

    let keyboardObserver = QuickLayoutKeyboardObserver()

    private var keyboardContext = QuickLayoutKeyboardContext.hidden {
        didSet {
            if oldValue != keyboardContext { // 避免首次出现动画
                animateLayoutChange()
            }
        }
    }

    private var keyboardHeight: CGFloat {
        keyboardContext.height
    }

    private var cancellables : Set<AnyCancellable> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        textField.placeholder = "输入文本"
        textField.borderStyle = .roundedRect


        var config = UIButton.Configuration.filled()
        config.title = "提交"
        config.cornerStyle = .capsule     // ✅ 胶囊
        submitButton.configuration = config
        submitButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
    }

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }

    private func setupKeyboardObservers() {
        keyboardObserver.$context
            .sink { [weak self] context in
                self?.keyboardContext = context
            }
            .store(in: &cancellables)
    }


    private func animateLayoutChange() {
        UIView.animate(
            withDuration: keyboardContext.animationDuration,
            delay: 0,
            options: keyboardContext.animationOptions,
            animations: {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        )
    }

    var body: Layout {
        VStack(spacing: 16) {
            Spacer()

            textField
                .frame(height: 44)

            submitButton
                .frame(height: 50)
        }
        .padding(.horizontal, 20)
        .padding(.horizontal, quickLayoutSafeAreaInsets.maximumHorizontalInset)
        .padding(.bottom, max(keyboardHeight + 20, safeAreaInsets.bottom))
    }
}



#Preview {
    AnimatedKeyboardResponsiveView()
}
