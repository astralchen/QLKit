//
//  DemoLocalization.swift
//  Demo
//
//  Created by Codex on 2026/6/2.
//

import UIKit
import AppLocalization

@MainActor
enum DemoLocalization {
    static let localizationController = LocalizationController(
        supportedLocales: [.englishUS, .simplifiedChinese, .arabic],
        fallbackLocale: .englishUS,
        preferenceStore: UserDefaultsLocalePreferenceStore(
            key: "quicklayoutkit.demo.locale.identifier"
        )
    )

    static let resolver = LocalizedStringResolver(
        localeProvider: { localizationController.currentLocale },
        fallbackLocale: .englishUS,
        missingKeyHandler: { key, locale, _ in
            assertionFailure("Missing localization key '\(key)' for \(locale.identifier)")
        }
    )

    private static let sceneCoordinator = UIWindowSceneLocalizationCoordinator()
    private static var notificationToken: NSObjectProtocol?

    static var currentLayoutDirection: AppUserInterfaceLayoutDirection {
        localizationController.layoutDirection
    }

    static var currentUIKitDirection: UIUserInterfaceLayoutDirection {
        currentLayoutDirection.uiLayoutDirection
    }

    static func start() {
        sceneCoordinator.applyGlobalLayoutDirection(localizationController.currentLocale)

        guard notificationToken == nil else { return }
        notificationToken = NotificationCenter.default.addObserver(
            forName: LocalizationController.localizationDidChangeNotification,
            object: localizationController,
            queue: .main
        ) { notification in
            guard let change = notification.userInfo?[LocalizationController.localizationChangeUserInfoKey] as? LocalizationChange else {
                return
            }

            Task { @MainActor in
                sceneCoordinator.reloadAllScenes(
                    for: change,
                    rebuildRootWindows: change.layoutDirectionChanged,
                    animateRootRebuild: true,
                    updateAppearanceProxies: false
                )
            }
        }
    }

    @discardableResult
    static func setLocale(identifier: String) -> Bool {
        if identifier == LocalizationController.followSystemLocaleIdentifier {
            return localizationController.setFollowsSystemLocale()
        }

        return localizationController.setLocale(identifier: identifier)
    }

    @discardableResult
    static func refreshSystemLocaleIfNeeded() -> Bool {
        localizationController.refreshSystemLocaleIfNeeded()
    }

    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        resolver.string(key, bundle: .main, arguments: arguments)
    }

    static func text(_ key: String) -> String {
        resolver.string(key, bundle: .main)
    }

    static func localeDisplayName(_ locale: AppLocale) -> String {
        locale.localizedDisplayName(preferredBy: localizationController.currentLocale)
    }

    static func currentLanguageSummary() -> String {
        if localizationController.followsSystemLocale {
            return "\(text("language.follow.system")) (\(localizationController.currentLocale.identifier))"
        }

        return localizationController.currentLocale.identifier
    }

    static func installLanguageMenu(on viewController: UIViewController) {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            primaryAction: nil,
            menu: languageMenu()
        )
        item.accessibilityLabel = text("language.menu.accessibility")
        viewController.navigationItem.rightBarButtonItem = item
    }

    static func reloadLanguageMenu(on viewController: UIViewController) {
        viewController.navigationItem.rightBarButtonItem?.menu = languageMenu()
        viewController.navigationItem.rightBarButtonItem?.accessibilityLabel = text("language.menu.accessibility")
    }

    static func languageMenu() -> UIMenu {
        let follow = UIAction(
            title: text("language.follow.system"),
            subtitle: localeDisplayName(localizationController.currentLocale),
            image: localizationController.followsSystemLocale ? UIImage(systemName: "checkmark") : nil
        ) { _ in
            Task { @MainActor in
                setLocale(identifier: LocalizationController.followSystemLocaleIdentifier)
            }
        }

        let localeActions = localizationController.supportedLocales.map { locale in
            UIAction(
                title: locale.nativeDisplayName,
                subtitle: localeDisplayName(locale),
                image: (!localizationController.followsSystemLocale && locale == localizationController.currentLocale) ? UIImage(systemName: "checkmark") : nil
            ) { _ in
                Task { @MainActor in
                    setLocale(identifier: locale.identifier)
                }
            }
        }

        return UIMenu(
            title: text("language.menu.title"),
            image: UIImage(systemName: "globe"),
            children: [follow] + localeActions
        )
    }
}

extension UIViewController {
    @MainActor
    func installDemoLanguageMenu() {
        DemoLocalization.installLanguageMenu(on: self)
    }

    @MainActor
    func reloadDemoLanguageMenu() {
        DemoLocalization.reloadLanguageMenu(on: self)
    }

    @MainActor
    func applyDemoLayoutDirection(_ direction: UIUserInterfaceLayoutDirection) {
        let attribute = direction.appLayoutDirection.semanticContentAttribute
        view.semanticContentAttribute = attribute
        navigationController?.view.semanticContentAttribute = attribute
        navigationController?.navigationBar.semanticContentAttribute = attribute
    }
}
