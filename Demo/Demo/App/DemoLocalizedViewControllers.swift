//
//  DemoLocalizedViewControllers.swift
//  Demo
//
//  Created by Codex on 2026/6/2.
//

import UIKit
import AppLocalization
import QuickLayoutKit

class DemoQuickLayoutHostingController: QuickLayoutHostingController, LocalizedContentUpdating, UserInterfaceLayoutDirectionUpdating {
    var localizedTitleKey: String? { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        installDemoLanguageMenu()
        reloadLocalizedContent()
        reloadLayoutDirection(DemoLocalization.currentUIKitDirection)
    }

    func reloadLocalizedContent() {
        if let localizedTitleKey {
            title = DemoLocalization.text(localizedTitleKey)
            navigationItem.title = title
        }
        reloadDemoLanguageMenu()
        setNeedsQuickLayout()
    }

    func reloadLayoutDirection(_ direction: UIUserInterfaceLayoutDirection) {
        applyDemoLayoutDirection(direction)
        setNeedsQuickLayout()
    }
}

class DemoViewController: UIViewController, LocalizedContentUpdating, UserInterfaceLayoutDirectionUpdating {
    var localizedTitleKey: String? { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        installDemoLanguageMenu()
        reloadLocalizedContent()
        reloadLayoutDirection(DemoLocalization.currentUIKitDirection)
    }

    func reloadLocalizedContent() {
        if let localizedTitleKey {
            title = DemoLocalization.text(localizedTitleKey)
            navigationItem.title = title
        }
        reloadDemoLanguageMenu()
    }

    func reloadLayoutDirection(_ direction: UIUserInterfaceLayoutDirection) {
        applyDemoLayoutDirection(direction)
    }
}


#Preview {
   UINavigationController(rootViewController: DemoQuickLayoutHostingController())
}
