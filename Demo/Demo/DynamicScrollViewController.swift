//
//  DynamicScrollViewController.swift
//  Demo
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout
import QLKit

class DynamicScrollViewController: QLHostingController {


    let addButton = UIButton(type: .system)

    private var items: [UIView] = []

    let scrollView: QLScrollView = QLScrollView()



    override var body: Layout {
        VStack(spacing: 12) {
            addButton

            ScrollView(scrollView) {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        item
                            .frame(height: 80)
                    }
                }
                .padding(.all, 16)
            }
        }
        .padding(.top, view.safeAreaInsets.top)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // 初始化项目
        addItems(count: 10)

        // 添加按钮用于动态添加内容

        addButton.setTitle("Add Item", for: .normal)
        addButton.addTarget(self, action: #selector(addItemTapped), for: .touchUpInside)
        addButton.frame = CGRect(x: 16, y: 50, width: 100, height: 44)
        view.addSubview(addButton)
    }



    @objc private func addItemTapped() {
        addItems(count: 1)
        setNeedsLayoutUpdate()
        layoutIfNeeded()
        scrollView.scrollToBottom()
    }

    private func addItems(count: Int) {
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen,
            .systemYellow, .systemOrange, .systemPurple,
            .systemPink, .systemIndigo, .systemTeal
        ]

        for _ in 0..<count {
            let view = UIView()
            view.backgroundColor = colors.randomElement()
            view.layer.cornerRadius = 8
            items.append(view)
        }
    }
}


#Preview {
   UINavigationController(rootViewController: DynamicScrollViewController())
}
