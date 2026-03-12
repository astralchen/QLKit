//
//  KeyboardHandlingViewController.swift
//  Demo
//
//  Created by Sondra on 2026/1/27.
//

import UIKit
import QuickLayout
import QLKit

class KeyboardHandlingViewController: QLHostingController {

    override var body: any Layout {
        ZStack {
            AnimatedKeyboardResponsiveView()
        }
    }

}



#Preview {
    UINavigationController(rootViewController: KeyboardHandlingViewController())
}
