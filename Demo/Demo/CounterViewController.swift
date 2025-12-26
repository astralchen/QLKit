//
//  CounterViewController.swift
//  Demo
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout
import QLKit

class CounterViewController: QLHostingController {

    private var count = 0 {
        didSet {
            updateLabels()
            setNeedsLayoutUpdate()
        }
    }

    let counterLabel = UILabel()
    let incrementButton = UIButton(type: .system)
    let decrementButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        counterLabel.font = .systemFont(ofSize: 48, weight: .bold)
        counterLabel.textAlignment = .center

        incrementButton.setTitle("Increment", for: .normal)
        incrementButton.addTarget(self, action: #selector(increment), for: .touchUpInside)

        decrementButton.setTitle("Decrement", for: .normal)
        decrementButton.addTarget(self, action: #selector(decrement), for: .touchUpInside)

        updateLabels()
    }

    override var body: Layout {
        VStack(alignment: .center, spacing: 32) {
            Spacer()

            counterLabel

            HStack(spacing: 16) {
                decrementButton
                incrementButton
            }

            Spacer()
        }
        .padding(.all, 24)
    }

    @objc private func increment() {
        count += 1
    }

    @objc private func decrement() {
        count -= 1
    }

    private func updateLabels() {
        counterLabel.text = "\(count)"
    }
}

#Preview {
   UINavigationController(rootViewController: CounterViewController())
}
