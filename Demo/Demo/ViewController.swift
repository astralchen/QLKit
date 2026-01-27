//
//  ViewController.swift
//  Demo
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout
import QLKit

class ViewController: QLHostingController {
    
    let viewControllerTypes: [UIViewController.Type] = [
        HorizontalScrollViewViewController.self,
        ProfileViewController.self,
        CounterViewController.self,
        DynamicScrollViewController.self,
        DashboardViewController.self,
        MesssageViewController.self,
        KeyboardHandlingViewController.self
    ]
    
    var buttons: [UIButton] = []
    let scrollView = QLScrollView()

    override var body: Layout {
        ScrollView(scrollView) {
            VStack(spacing: 12) {
                ForEach(buttons) { button in
                    button
                        .resizable()
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, view.safeAreaEdgeInsets.leading)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Examples"
        
        // Create buttons for each ViewController type
        buttons = viewControllerTypes.enumerated().map { index, vcType in
            var config = UIButton.Configuration.filled()
            
            config.title = String(describing: vcType)
            config.baseBackgroundColor = .systemBlue.withAlphaComponent(0.1)
            config.baseForegroundColor = .systemBlue
            config.cornerStyle = .medium
            
            let button = UIButton(configuration: config)
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            return button
        }
    }
    
    
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let vcType = viewControllerTypes[sender.tag]
        let vc = vcType.init()
        vc.navigationItem.title = String(describing: vcType)
        navigationController?.pushViewController(vc, animated: true)
    }
}


#Preview {
    UINavigationController(rootViewController: ViewController())
}
