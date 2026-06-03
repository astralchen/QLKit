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
    let diagnosticsBackgroundView = UIView()
    let diagnosticsLabel = UILabel()

    let keyboardObserver = QuickLayoutKeyboardObserver()

    private var keyboardContext = QuickLayoutKeyboardContext.hidden {
        didSet {
            updateKeyboardDiagnostics()
            if oldValue != keyboardContext { // 避免首次出现动画
                animateLayoutChange()
            }
        }
    }

    private var keyboardHeight: CGFloat {
        keyboardContext.resolved(in: self).height
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
        textField.borderStyle = .roundedRect

        diagnosticsLabel.numberOfLines = 0
        diagnosticsLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        diagnosticsLabel.textColor = .secondaryLabel

        diagnosticsBackgroundView.backgroundColor = .secondarySystemBackground
        diagnosticsBackgroundView.layer.cornerRadius = 12
        diagnosticsBackgroundView.layer.masksToBounds = true

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule     // ✅ 胶囊
        submitButton.configuration = config
        submitButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        reloadLocalizedContent()
    }

    func reloadLocalizedContent() {
        textField.placeholder = DemoLocalization.text("keyboard.placeholder")
        submitButton.configuration?.title = DemoLocalization.text("common.submit")
        updateKeyboardDiagnostics()
        setNeedsLayout()
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

    private func updateKeyboardDiagnostics() {
        let resolved = keyboardContext.resolved(in: self)
        diagnosticsLabel.text = """
        \(DemoLocalization.text("keyboard.diagnostics.title"))
        event: \(keyboardContext.event.demoDescription)
        raw: \(keyboardContext.endFrame.demoDescription)
        intersection: \(resolved.intersection.demoDescription)
        height: \(Int(resolved.height))
        """
    }

    var body: Layout {
        VStack(spacing: 16) {
            Spacer()

            diagnosticsLabel
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    diagnosticsBackgroundView
                }

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

private extension QuickLayoutKeyboardEvent {
    var demoDescription: String {
        switch self {
        case .willShow:
            return "willShow"
        case .willHide:
            return "willHide"
        case .willChangeFrame:
            return "willChangeFrame"
        case .didChangeFrame:
            return "didChangeFrame"
        case .unknown:
            return "unknown"
        }
    }
}

private extension CGRect {
    var demoDescription: String {
        guard !isNull else { return "null" }
        return "(\(Int(origin.x)), \(Int(origin.y)), \(Int(width)), \(Int(height)))"
    }
}
