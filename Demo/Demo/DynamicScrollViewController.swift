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


    lazy var addButton:  UIButton =  {
        var config = UIButton.Configuration.filled()
        config.title = "Add Item"
        config.cornerStyle = .capsule
        config.buttonSize = .medium
        
        let addButton = UIButton(configuration: config)
        addButton.addTarget(self, action: #selector(addItemTapped), for: .touchUpInside)
        addButton.backgroundColor = .red
        return addButton
    }()

    private var items: [UIView] = []

    let scrollView: QLScrollView = QLScrollView()

    override var body: Layout {
        ScrollView(scrollView) {
            VStack(spacing: 12) {
                ForEach(items) { item in
                    item
                        .frame(height: 80)
                }
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, view.safeAreaEdgeInsets.leading)
        }
        .overlay(alignment: .topTrailing) {
            addButton
                .padding(.trailing, 16)
                .padding(.vertical, 8)
                .padding(.trailing, view.safeAreaEdgeInsets.trailing)
                .padding(.top, view.safeAreaEdgeInsets.top)
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // 初始化项目
        addItems(count: 10)
    }



    @objc private func addItemTapped() {
         addItems(count: 1)

        let newItem = items.last!

        // ① Complete the layout first (without animation)
        UIView.performWithoutAnimation {
            setNeedsLayoutUpdate()
            layoutIfNeeded()
        }

        newItem.animateAppear(offsetY: max(view.safeAreaEdgeInsets.bottom, 12))

        scrollView.scrollToBottom(animated: true)
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

extension UIView {
    func animateAppear(offsetY: CGFloat = 12, duration: TimeInterval = 0.25) {
        // ② Set the initial state
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: offsetY)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}


#Preview {
    DynamicScrollViewController()
}
