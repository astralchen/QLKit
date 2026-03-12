//
//  SemanticContentDemoViewController.swift
//  Demo
//
//  Created by Sondra on 2026/1/30.
//

import UIKit
import QLKit
import QuickLayout
/*
UIKit semanticContentAttribute 行为整理（实战版）

一、三个层级，先记住这张心智模型 🧠

1️⃣ 系统方向
    •    UIApplication.shared.userInterfaceLayoutDirection
    •    由系统语言决定（中文 / 英文 = LTR）

⸻

2️⃣ View 语义
    •    UIView.semanticContentAttribute
    •    作用于：
    •    Auto Layout 的 leading / trailing
    •    StackView 排列
    •    部分控件内部布局

⚠️ 不是所有子控件都会完全继承

⸻

3️⃣ 控件内部子布局（坑最多）
    •    UIButton 的 image / title
    •    UITextField 的 leftView / rightView
    •    UICollectionViewCell 的内部 subviews

👉 很多都是“必须自己 force”
*/

// MARK: - Main Demo Controller
class SemanticContentDemoViewController: QLHostingController {

    let scrollView = QLScrollView()
    let titleLabel = UILabel()
    let descLabel = UILabel()

    // Demo sections
    let unspecifiedSection = DemoSection(
        title: "1. Unspecified (默认)",
        semantic: .unspecified
    )

    let ltrSection = DemoSection(
        title: "2. Force Left-to-Right",
        semantic: .forceLeftToRight
    )

    let rtlSection = DemoSection(
        title: "3. Force Right-to-Left",
        semantic: .forceRightToLeft
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        titleLabel.text = "UISemanticContentAttribute Demo"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center

        descLabel.text = "观察 forceLeftToRight 和 forceRightToLeft 的布局差异"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
    }

    override var body: Layout {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                titleLabel
                descLabel
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))

            // Scrollable content
            ScrollView(scrollView) {
                VStack(spacing: 20) {
                    unspecifiedSection
                    ltrSection
                    rtlSection
                }
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }
        }
        .padding(.top, view.safeAreaInsets.top)
    }
}

// MARK: - Demo Section Component
@QuickLayout
class DemoSection: UIView {

    let titleLabel = UILabel()
    let semantic: UISemanticContentAttribute

    // Example 1: Icon + Text
    let example1 = ExampleRow1()

    // Example 2: Leading/Trailing
    let example2 = ExampleRow2()

    // Example 3: Image alignment
    let example3 = ExampleRow3()

    // Example 4: Button with icon
    let example4 = ExampleRow4()

    // Example 5: Progress bar
    let example5 = ExampleRow5()

    init(title: String, semantic: UISemanticContentAttribute) {
        self.semantic = semantic
        super.init(frame: .zero)

        setupViews(title: title)
        self.semanticContentAttribute = semantic
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(title: String) {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        example1.semanticContentAttribute = semantic
        example2.semanticContentAttribute = semantic
        example3.semanticContentAttribute = semantic
        example4.semanticContentAttribute = semantic
        example5.semanticContentAttribute = semantic
    }

    var body: Layout {
        VStack(spacing: 12) {
            titleLabel
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))

            example1
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            example2
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            example3
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            example4
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            example5
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
        }
    }
}

@QuickLayout
class ExampleRow1: UIView {
    let iconLabel = UILabel()
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 8

        iconLabel.text = "📱"
        iconLabel.font = .systemFont(ofSize: 32)

        textLabel.text = "手机图标"
        textLabel.font = .systemFont(ofSize: 16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var body: Layout {
        HStack(spacing: 12) {
            iconLabel
                .frame(width: 32, height: 32)
            textLabel
            Spacer()
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

@QuickLayout
class ExampleRow2: UIView {
    let leadingView = UIView()
    let centerLabel = UILabel()
    let trailingView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8

        leadingView.backgroundColor = .systemBlue
        leadingView.layer.cornerRadius = 4

        trailingView.backgroundColor = .systemRed
        trailingView.layer.cornerRadius = 4

        centerLabel.text = "Leading ↔ Trailing"
        centerLabel.font = .systemFont(ofSize: 14)
        centerLabel.textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var body: Layout {
        HStack(spacing: 8) {
            leadingView
                .frame(width: 40, height: 40)
            centerLabel
            trailingView
                .frame(width: 40, height: 40)
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

@QuickLayout
class ExampleRow3: UIView {
    let imageView = UIImageView()
    let descLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 8

        imageView.backgroundColor = .systemGreen
        imageView.layer.cornerRadius = 20
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        descLabel.text = "头像和描述文字"
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.numberOfLines = 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var body: Layout {
        HStack(spacing: 12) {
            imageView
                .resizable()
                .frame(width: 40, height: 40)
            descLabel
            Spacer()
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

@QuickLayout
class ExampleRow4: UIView {
    let button = RTLAwareButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 8

        button.setTitle(" 下一步", for: .normal)
        button.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var body: Layout {
        button
            .frame(height: 44)
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

class RTLAwareButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        let needed: UISemanticContentAttribute =
            (superview?.effectiveUserInterfaceLayoutDirection == .rightToLeft)
            ? .forceRightToLeft : .forceLeftToRight
        if semanticContentAttribute != needed {
            semanticContentAttribute = needed
        }
    }
}

@QuickLayout
class ExampleRow5: UIView {
    let progressBar = UIView()
    let progressFill = UIView()
    let percentLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        layer.cornerRadius = 8

        progressBar.backgroundColor = .systemGray5
        progressBar.layer.cornerRadius = 4

        progressFill.backgroundColor = .systemBlue
        progressFill.layer.cornerRadius = 4

        percentLabel.text = "75%"
        percentLabel.font = .systemFont(ofSize: 12, weight: .medium)
        percentLabel.textColor = .systemBlue

        progressBar.addSubview(progressFill)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressFill.frame = CGRect(
            x: 0,
            y: 0,
            width: progressBar.bounds.width * 0.75,
            height: progressBar.bounds.height
        )
    }

    var body: Layout {
        HStack(spacing: 8) {
            progressBar
                .frame(height: 8)
            percentLabel
                .frame(width: 50)
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

// MARK: - Preview

#Preview {
    UINavigationController(rootViewController: SemanticContentDemoViewController())
}
