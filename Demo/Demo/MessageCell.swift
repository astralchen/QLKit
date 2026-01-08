//
//  MessageCell.swift
//  MessageCell
//
//  Created by Sondra on 2025/12/17.
//

import UIKit
import QuickLayout

@QuickLayout
final class MessageCell: UICollectionViewCell {

    let avatarView = UIImageView()
    let titleLabel = UILabel()
    let messageLabel = UILabel()

    var body: Layout {
        HStack(alignment: .top, spacing: 8) {

            avatarView
                .resizable()
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                titleLabel
                messageLabel
            }
            Spacer()

        }
        .padding(12)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        avatarView.backgroundColor = .systemPink
        avatarView.tintColor = .white
        avatarView.contentMode = .scaleAspectFit
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true

        titleLabel.font = .boldSystemFont(ofSize: 14)
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(_ model: MessageModel) {
        titleLabel.text = model.title
        messageLabel.text = model.message
        avatarView.image = UIImage(systemName: model.imageName)
        setNeedsLayout()
    }



    /// sizeThatFits for QuickLayout macro body
    /// - Pass constrained width with unconstrained height to let the layout
    ///   compute the natural content height.
    /// - Works well for self-sizing UICollectionViewCell.
    /// Docs:
    /// https://facebookincubator.github.io/QuickLayout/how-to-use/macro-layout-integration-isBodyEnabled/
    /// https://facebookincubator.github.io/QuickLayout/how-to-use/macro-layout-integration-dos/
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // Constrain width; allow height to grow for natural measurement
        let proposedSize = CGSize(width: size.width, height: .infinity)
        // Alternative: if macro body sizing is enabled, measure via body
        // let measured = body.sizeThatFits(proposedSize)
        // return measured
        // Measure via QuickLayout; fallback to incoming size if unavailable
        return _QuickLayoutViewImplementation.sizeThatFits(self, size: proposedSize) ?? size
    }
}


#Preview {
    MesssageViewController()
}
