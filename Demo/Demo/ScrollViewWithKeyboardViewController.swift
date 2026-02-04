//
//  ScrollViewWithKeyboardViewController.swift
//  Demo
//
//  Created by 辰宸 on 2026/1/27.
//

import UIKit
import QuickLayout
import QLKit
import Combine

// MARK: - Header View

@QuickLayout
class FormHeaderView: UIView {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .systemBlue.withAlphaComponent(0.1)
        layer.cornerRadius = 16

        titleLabel.text = "用户信息表单"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .systemBlue

        subtitleLabel.text = "请填写以下信息"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
    }

    var body: Layout {
        VStack(spacing: 4) {
            titleLabel
            subtitleLabel
        }
        .padding(20)
    }
}

// MARK: - Form Field View

@QuickLayout
class FormFieldView: UIView {

    let textField: UITextField
    let iconView = UIImageView()
    let containerView = UIView()

    init(textField: UITextField, placeholder: String, icon: String) {
        self.textField = textField
        super.init(frame: .zero)
        setupViews(placeholder: placeholder, icon: icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(placeholder: String, icon: String) {
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit

        textField.placeholder = placeholder
    }

    var body: Layout {
        ZStack {
            containerView

            HStack(spacing: 12) {
                iconView
                    .frame(width: 24, height: 24)

                textField
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 50)
    }
}

// MARK: - Notes Field View

@QuickLayout
class NotesFieldView: UIView {

    let label = UILabel()
    let textView: UITextView

    init(textView: UITextView) {
        self.textView = textView
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        label.text = "备注"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
    }

    var body: Layout {
        VStack(spacing: 8) {
            label

            textView
                .frame(height: 120)
        }
    }
}

// MARK: - Main ViewController

class ScrollViewWithKeyboardViewController: QLHostingController {

    let scrollView = QLScrollView()
    let keyboardObserver = AnimatedKeyboardObserver()

    // UI Components
    let headerView = FormHeaderView()

    let nameTextField = UITextField()
    let emailTextField = UITextField()
    let phoneTextField = UITextField()
    let addressTextField = UITextField()
    let notesTextView = UITextView()
    let submitButton = UIButton(type: .system)

    // Form Field Views
    lazy var nameFieldView = FormFieldView(textField: nameTextField, placeholder: "姓名", icon: "person.fill")
    lazy var emailFieldView = FormFieldView(textField: emailTextField, placeholder: "邮箱", icon: "envelope.fill")
    lazy var phoneFieldView = FormFieldView(textField: phoneTextField, placeholder: "电话", icon: "phone.fill")
    lazy var addressFieldView = FormFieldView(textField: addressTextField, placeholder: "地址", icon: "location.fill")
    lazy var notesFieldView = NotesFieldView(textView: notesTextView)

    private lazy var keyboardHeight: CGFloat = keyboardObserver.keyboardHeight {
        didSet {
            if oldValue != keyboardHeight {
                updateContentInset()
                animateKeyboardChange()
                // 键盘高度变化时，重新调整当前激活输入框的位置
                if keyboardHeight > 0 {
                    scrollToCurrentActiveField()
                }
            }
        }
    }

    private var currentActiveField: UIView?
    private var cancellables: Set<AnyCancellable> = []

    override var body: Layout {
        ScrollView(scrollView, axis: .vertical) {
            VStack(spacing: 20) {
                // Header
                headerView
                    .frame(height: 100)

                // Form Fields
                nameFieldView
                emailFieldView
                phoneFieldView
                addressFieldView

                // Notes Field
                notesFieldView

                // Submit Button
                submitButton
                    .frame(height: 50)
            }
            .padding(.horizontal, 20)
            .padding(.horizontal, view.safeAreaInsets.left)
            .padding(.top, view.safeAreaInsets.top + 20)
            .padding(.bottom, max(view.safeAreaInsets.bottom, 10))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupKeyboardObservers()
        setupGestures()
    }

    private func setupViews() {
        title = "表单示例"
        scrollView.backgroundColor = .systemBackground
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive

        // Configure TextFields
        [nameTextField, emailTextField, phoneTextField, addressTextField].forEach { textField in
            textField.borderStyle = .roundedRect
            textField.backgroundColor = .secondarySystemBackground
            textField.layer.cornerRadius = 12
            textField.font = .systemFont(ofSize: 16)
            textField.returnKeyType = .next
            textField.delegate = self
        }

        addressTextField.returnKeyType = .done

        // Configure Email TextField
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none

        // Configure Phone TextField
        phoneTextField.keyboardType = .phonePad

        // Configure TextView
        notesTextView.backgroundColor = .secondarySystemBackground
        notesTextView.layer.cornerRadius = 12
        notesTextView.font = .systemFont(ofSize: 16)
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        notesTextView.delegate = self

        // Configure Submit Button
        var config = UIButton.Configuration.filled()
        config.title = "提交表单"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = .init(top: 14, leading: 32, bottom: 14, trailing: 32)
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8

        submitButton.configuration = config
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    private func setupKeyboardObservers() {
        keyboardObserver.$keyboardHeight
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)

        // 监听输入框开始编辑
        NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)
            .merge(with: NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification))
            .sink { [weak self] notification in
                if let field = notification.object as? UIView {
                    self?.currentActiveField = field
                    self?.scrollToActiveField(field)
                }
            }
            .store(in: &cancellables)

        // 监听键盘即将显示（用于处理键盘类型切换）
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in
                self?.scrollToCurrentActiveField()
            }
            .store(in: &cancellables)
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func updateContentInset() {
        // 直接设置 contentInset 来处理键盘
        let bottom = keyboardHeight > 0 ? keyboardHeight : view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottom
        scrollView.verticalScrollIndicatorInsets.bottom = bottom
    }

    private func animateKeyboardChange() {
        UIView.animate(
            withDuration: keyboardObserver.animationDuration,
            delay: 0,
            options: keyboardObserver.animationCurve,
            animations: {
                self.setNeedsLayoutUpdate()
                self.layoutIfNeeded()
            }
        )
    }

    private func scrollToCurrentActiveField() {
        guard let field = currentActiveField else { return }
        scrollToActiveField(field)
    }

    private func scrollToActiveField(_ field: UIView?) {
        guard let field = field, keyboardHeight > 0 else { return }

        // 使用较长的延迟确保键盘动画和布局更新完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }

            // 获取输入框在 scrollView 中的位置
            let fieldFrame = field.convert(field.bounds, to: self.scrollView)

            // 计算可见区域的高度（scrollView 高度 - 键盘高度）
            let visibleHeight = self.scrollView.bounds.height - self.keyboardHeight

            // 计算理想的输入框位置（距离可见区域顶部 1/4 处）
            let idealTopOffset: CGFloat = visibleHeight * 0.25

            // 计算需要滚动到的目标位置
            let targetY = fieldFrame.minY - idealTopOffset

            // 确保不超过最大滚动范围
            let maxY = max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
            let finalY = max(0, min(targetY, maxY))

            // 只有当需要滚动的距离超过一定阈值时才执行滚动
            let currentOffset = self.scrollView.contentOffset.y
            if abs(finalY - currentOffset) > 10 {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: finalY), animated: true)
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
        currentActiveField = nil
    }

    @objc private func submitTapped() {
        dismissKeyboard()

        let formData = """
        姓名: \(nameTextField.text ?? "")
        邮箱: \(emailTextField.text ?? "")
        电话: \(phoneTextField.text ?? "")
        地址: \(addressTextField.text ?? "")
        备注: \(notesTextView.text ?? "")
        """

        let alert = UIAlertController(title: "表单提交", message: formData, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension ScrollViewWithKeyboardViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            phoneTextField.becomeFirstResponder()
        case phoneTextField:
            addressTextField.becomeFirstResponder()
        case addressTextField:
            notesTextView.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UITextViewDelegate

extension ScrollViewWithKeyboardViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // 可以添加字数限制等逻辑
    }
}

// MARK: - Preview

#Preview {
    let nav = UINavigationController(rootViewController: ScrollViewWithKeyboardViewController())
    return nav
}
