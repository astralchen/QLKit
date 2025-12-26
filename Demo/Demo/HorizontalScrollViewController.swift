//
//  HorizontalScrollViewController.swift
//  Demo
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout
import QLKit

class HorizontalScrollViewViewController: QLHostingController {

    let scrollView = QLScrollView()

    let views: [UIView] =  {

        let colors: [UIColor] = [.systemRed, .systemPink, .systemOrange, .systemPurple, .systemCyan]

        return (1...10).map { _ in
            let view = UIView()
            view.backgroundColor = colors.randomElement()
            view.layer.cornerRadius = 16
            return view
        }

    }()

    override var body: Layout {

        ScrollView(scrollView, axis: .horizontal) {
            HStack(spacing: 16) {
                ForEach(views) { view in
                    view
                        .frame(width: 200)

                }
            }
            .padding(16)
            .padding(view.safeAreaEdgeInsets)

        }

    }


    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .systemGray6
    }

}

#Preview {
    HorizontalScrollViewViewController()
}
