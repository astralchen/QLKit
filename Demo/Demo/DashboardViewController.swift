//
//  DashboardViewController.swift
//  Demo
//
//  Created by Sondra on 2025/12/26.
//

import UIKit
import QuickLayout
import QLKit

class DashboardViewController: QLHostingController {

    let profileImageView = UIImageView()
    let nameLabel = UILabel()
    let scoreLabel = UILabel()
    let achievementLabel = UILabel()
    let statsView1 = UIView()
    let statsView2 = UIView()
    let statsView3 = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure views
        profileImageView.image = UIImage(systemName: "apple.intelligence")
        profileImageView.backgroundColor = .systemBlue
        profileImageView.layer.cornerRadius = 25
        profileImageView.clipsToBounds = true
        profileImageView.tintColor = .systemPink

        nameLabel.text = "Jane Smith"
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        scoreLabel.text = "Score: 1250"
        scoreLabel.font = .systemFont(ofSize: 14)

        achievementLabel.text = "🏆 Top Performer"
        achievementLabel.font = .systemFont(ofSize: 12)

        [statsView1, statsView2, statsView3].forEach {
            $0.backgroundColor = .systemGray6
            $0.layer.cornerRadius = 8
        }
    }

    override var body: Layout {
        VStack(spacing: 24) {
            // Header Card
            HStack(spacing: 12) {
                profileImageView
                    .resizable()
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    nameLabel
                    scoreLabel
                    achievementLabel
                }

                Spacer()
            }
            .padding(.all, 16)
            .background {
                makeCardBackground()
            }

            // Stats Grid
            HStack(spacing: 12) {
                statsView1
                    .frame(height: 100)
                statsView2
                    .frame(height: 100)
                statsView3
                    .frame(height: 100)
            }

            Spacer()
        }
        .padding(.all, 16)
        .padding(.top, view.safeAreaInsets.top)
    }

    private func makeCardBackground() -> UIView {
        let background = UIView()
        background.backgroundColor = .systemBackground
        background.layer.cornerRadius = 12
        background.layer.shadowColor = UIColor.black.cgColor
        background.layer.shadowOpacity = 0.1
        background.layer.shadowRadius = 8
        background.layer.shadowOffset = CGSize(width: 0, height: 2)
        return background
    }
}

#Preview {
   UINavigationController(rootViewController: DashboardViewController())
}
