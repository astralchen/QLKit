//
//  MessageCell.swift
//  MessageCell
//
//  Created by Sondra on 2025/12/17.
//

import UIKit
import QuickLayout
import QLKit

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

        avatarView.backgroundColor = .systemPink.withAlphaComponent(0.2)
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
        avatarView.tintColor = model.themeColor
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
        let proposedSize = layoutLimit(proposed: size)
        // Alternative: if macro body sizing is enabled, measure via body
        // let measured = body.sizeThatFits(proposedSize)
        // return measured
        // Measure via QuickLayout; fallback to incoming size if unavailable
        return _QuickLayoutViewImplementation.sizeThatFits(self, size: proposedSize) ?? size
    }

    override func flexibility(for axis: Axis) -> Flexibility {
        switch axis {
        case .horizontal:
            return .fixedSize
        case .vertical:
            return .fullyFlexible
        }
    }
}


#Preview("简短") {
    previewCell(MessageModel.mockData[0])
}


#Preview("节选") {
    previewCell(MessageModel.mockData[8])
}


func makeMessageCell(with model: MessageModel) -> MessageCell {
    let cell = MessageCell()
    cell.backgroundColor = .systemGroupedBackground
    cell.layer.cornerRadius = 8
    cell.configure(model)
    return cell
}

private func previewCell(_ model: MessageModel) -> QLComposableHostingController {
    QLComposableHostingController {
        makeMessageCell(with: model)
            .padding(16)
    }
}
