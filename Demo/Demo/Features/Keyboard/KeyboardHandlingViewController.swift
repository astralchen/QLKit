//
//  KeyboardHandlingViewController.swift
//  Demo
//
//  Created by Sondra on 2026/1/27.
//

import UIKit
import QuickLayout
import QuickLayoutKit

class KeyboardHandlingViewController: QuickLayoutHostingController {

    override var body: any Layout {
        ZStack {
            AnimatedKeyboardResponsiveView()
        }
    }

}



#Preview {
    UINavigationController(rootViewController: KeyboardHandlingViewController())
}
