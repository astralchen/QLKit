//
//  ProfileViewController.swift
//  Demo
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout
import QuickLayoutKit

class ProfileViewController: DemoQuickLayoutHostingController {

    override var localizedTitleKey: String? { "demo.profile.title" }

    let avatarImageView = UIImageView()
    let nameLabel = UILabel()
    let bioLabel = UILabel()

    let borderView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure views
        avatarImageView.image = UIImage(systemName: "apple.intelligence")
        avatarImageView.backgroundColor = .systemGray
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true

        borderView.layer.cornerRadius = 40
        borderView.layer.borderColor = UIColor.systemRed.cgColor
        borderView.layer.borderWidth = 4

        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)

        bioLabel.textColor = .secondaryLabel
        bioLabel.numberOfLines = 0
    }

    override func reloadLocalizedContent() {
        super.reloadLocalizedContent()
        nameLabel.text = DemoLocalization.text("profile.name")
        bioLabel.text = DemoLocalization.text("profile.bio")
    }

    override var body: Layout {
        VStack(alignment: .center, spacing: 16) {
            avatarImageView
                .resizable()
                .frame(width: 80, height: 80)
                .overlay {
                    borderView
                }

            nameLabel

            bioLabel
                .padding(.horizontal, 20)
        }
        .padding(.all, 24)
    }
}

#Preview {
    UINavigationController(rootViewController: ProfileViewController())
}
